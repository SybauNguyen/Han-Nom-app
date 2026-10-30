import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../data/dictionary_search.dart';
import '../../data/han_character.dart';
import '../../data/han_seed_data.dart';
import '../../data/legacy_nom_codepoints.dart';
import '../../data/models/cjk_character.dart';

/// Web/Edge fallback: the same query API backed by an in-memory, deduplicated
/// catalogue. Android/iOS/desktop use SQLite from database_service_native.dart.
class DatabaseService {
  Future<void>? _initializing;
  final Map<String, HanCharacter> _catalogue = <String, HanCharacter>{};
  final Map<String, CjkCharacter> _cjkCatalogue = <String, CjkCharacter>{};
  String? lastImportError;
  String? lastCjkImportError;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    for (final character in seedCharacters) {
      _catalogue[character.character] = character.copyWith(inCurriculum: true);
    }
    try {
      final raw = await rootBundle.loadString('assets/data/dictionary.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('dictionary.json phải là một mảng JSON.');
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final character = HanCharacter.fromDictionaryMap(Map<String, dynamic>.from(item));
          if (!isNomDataEnabled && (character.isNom || retiredNomCodepoints.contains(character.character))) continue;
          _catalogue.putIfAbsent(character.character, () => character.copyWith(inCurriculum: false));
        } catch (_) {
          // One bad external record should not block the rest of the dictionary.
        }
      }
      lastImportError = null;
    } catch (error) {
      lastImportError = error.toString();
    }

    try {
      final rawCjk = await rootBundle.loadString('assets/data/master_dictionary.json');
      final decodedCjk = jsonDecode(rawCjk);
      if (decodedCjk is! List) {
        throw const FormatException('master_dictionary.json phải là một mảng JSON.');
      }
      _cjkCatalogue.clear();
      for (final item in decodedCjk) {
        if (item is! Map) continue;
        try {
          final record = CjkCharacter.fromMap(Map<String, dynamic>.from(item));
          if (record.charTraditional.trim().isEmpty) continue;
          _cjkCatalogue[record.charTraditional] = record;
        } catch (_) {
          // Một bản ghi CJK lỗi không được chặn từ điển Hán-Việt cũ.
        }
      }
      lastCjkImportError = null;
    } catch (error) {
      lastCjkImportError = error.toString();
    }
  }

  Future<CjkCharacter?> getCjkCharacter(String character) async {
    await initialize();
    final query = character.trim();
    if (query.isEmpty) return null;
    final exact = _cjkCatalogue[query];
    if (exact != null) return exact;
    for (final item in _cjkCatalogue.values) {
      if (item.charSimplified == query || item.charShinjitai == query) return item;
    }
    return null;
  }

  Future<List<CjkCharacter>> getCjkCharacters({int limit = 100, int offset = 0}) async {
    await initialize();
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit.clamp(1, 1000).toInt();
    return _cjkCatalogue.values.skip(safeOffset).take(safeLimit).toList();
  }

  Future<int> countDictionary({String? type, bool? inCurriculum, String? query}) async {
    await initialize();
    final filtered = _catalogue.values.where((character) {
      if (type != null && type != 'Tất cả' && character.type != type) return false;
      if (inCurriculum != null && character.inCurriculum != inCurriculum) return false;
      return true;
    });
    return searchHanCharacters(filtered, query ?? '').length;
  }

  Future<List<HanCharacter>> searchDictionary(
    String query, {
    String? type,
    int limit = 100,
    int offset = 0,
  }) async {
    await initialize();
    final typeFiltered = _catalogue.values.where((character) => type == null || type == 'Tất cả' || character.type == type);
    final results = searchHanCharacters(typeFiltered, query);
    if (offset >= results.length) return <HanCharacter>[];
    final safeLimit = limit.clamp(1, 500).toInt();
    return results.skip(offset).take(safeLimit).toList();
  }

  Future<List<HanCharacter>> getCurriculumCharacters({required String type}) async {
    await initialize();
    return _catalogue.values.where((character) => character.type == type && character.inCurriculum).toList();
  }

  Future<List<HanCharacter>> getCharactersForLesson({required String type, required int lessonNumber}) async {
    await initialize();
    final typeUnits = type == 'Nôm'
        ? lessonUnits.skip(hanCoreLessonCount).toList()
        : lessonUnits.take(hanCoreLessonCount).toList();
    if (lessonNumber < 1 || lessonNumber > typeUnits.length) return <HanCharacter>[];
    final unit = typeUnits[lessonNumber - 1];
    return unit.characters.map((symbol) => _catalogue[symbol]).whereType<HanCharacter>().toList();
  }

  Future<List<HanCharacter>> getHanReviewCharacters(int checkpointNumber, {int limit = 20}) async {
    await initialize();
    if (checkpointNumber < 1 || limit < 1) return <HanCharacter>[];
    final allHan = <HanCharacter>[];
    final firstUnit = (checkpointNumber - 1) * hanLessonsPerCycle;
    for (final unit in hanLessonUnits.skip(firstUnit).take(hanLessonsPerCycle)) {
      allHan.addAll(unit.characters.map((symbol) => _catalogue[symbol]).whereType<HanCharacter>());
    }
    allHan.shuffle(Random());
    return allHan.take(min(limit, allHan.length)).toList();
  }

  Future<List<HanCharacter>> getJumpAheadCharacters({int targetLessonNumber = 1, int limit = 10, String type = 'Hán'}) async {
    await initialize();
    if (targetLessonNumber <= 1 || targetLessonNumber > hanCoreLessonCount || limit < 1) return <HanCharacter>[];
    final typeUnits = type == 'Nôm'
        ? lessonUnits.skip(hanCoreLessonCount).toList()
        : lessonUnits.take(hanCoreLessonCount).toList();
    final past = <HanCharacter>[];
    if (targetLessonNumber > 1) {
      for (final unit in typeUnits.take(targetLessonNumber - 1)) {
        past.addAll(unit.characters.map((symbol) => _catalogue[symbol]).whereType<HanCharacter>());
      }
    }
    past.shuffle(Random());
    // Chỉ sử dụng các Node đứng trước bài thi, không thêm chữ tương lai làm dữ liệu bù.
    return past.take(min(limit, past.length)).toList();
  }
}
