import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:han_viet_duo/data/models/cjk_character.dart';
import 'package:han_viet_duo/state/app_state.dart';
import 'package:han_viet_duo/data/han_seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CJK model separates Chinese Simplified from Japanese Shinjitai', () {
    final cloud = CjkCharacter(
      charTraditional: '雲',
      charSimplified: '云',
      charShinjitai: '雲',
      meaningVi: 'mây',
      readingsHanViet: const ['vân'],
      readingsPinyin: const ['yún'],
      readingsOnyomi: const ['ウン'],
      readingsKunyomi: const ['くも'],
    );

    expect(cloud.getDisplayChar(SupplementaryLanguage.mandarin), '云');
    expect(cloud.getDisplayChar(SupplementaryLanguage.japanese), '雲');
    expect(cloud.getPrimaryReading(SupplementaryLanguage.mandarin), 'yún');
    expect(cloud.getPrimaryReading(SupplementaryLanguage.japanese), 'ウン');
    expect(cloud.getReadings(SupplementaryLanguage.none), isEmpty);
    expect(SupplementaryLanguage.none.flagEmoji, '🇻🇳');
    expect(SupplementaryLanguage.mandarin.flagEmoji, '🇨🇳');
    expect(SupplementaryLanguage.japanese.flagEmoji, '🇯🇵');
  });

  test('CJK model parses list fields saved as JSON or separator strings', () {
    final character = CjkCharacter.fromMap({
      'char_traditional': '國',
      'char_simplified': '国',
      'char_shinjitai': '国',
      'meaning_vi': 'nước, quốc gia',
      'readings_hanviet': '["quốc"]',
      'readings_pinyin': 'guó; guo',
      'readings_onyomi': ['コク'],
      'readings_kunyomi': null,
      'readings_hanja': null,
      'readings_jyutping': null,
    });

    expect(character.readingsHanViet, ['quốc']);
    expect(character.readingsPinyin, ['guó', 'guo']);
    expect(character.readingsOnyomi, ['コク']);
    expect(character.toMap()['char_simplified'], '国');
  });

  test('master dictionary covers lesson seed and number characters in both languages', () async {
    final raw = await rootBundle.loadString('assets/data/master_dictionary.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final records = decoded.map((item) => CjkCharacter.fromMap(Map<String, dynamic>.from(item as Map))).toList();
    final byTraditional = {for (final item in records) item.charTraditional: item};

    expect(records.length, greaterThanOrEqualTo(250));
    expect(byTraditional.length, records.length, reason: 'Mỗi chữ truyền thống chỉ được có một bản ghi');
    // Keep the whole bundled CJKV catalogue complete, not just the 250 lesson characters.
    for (final record in records) {
      expect(record.hasReadingFor(SupplementaryLanguage.mandarin), isTrue,
          reason: 'Thiếu Pinyin trong master dictionary: ${record.charTraditional}');
      expect(record.hasReadingFor(SupplementaryLanguage.japanese), isTrue,
          reason: 'Thiếu On'yomi trong master dictionary: ${record.charTraditional}');
    }
    expect(seedCharacters, hasLength(250));
    for (final seed in seedCharacters) {
      final character = seed.character;
      final record = byTraditional[character];
      expect(record, isNotNull, reason: 'Thiếu bản ghi CJKV $character');
      expect(record!.hasReadingFor(SupplementaryLanguage.mandarin), isTrue,
          reason: 'Thiếu Pinyin cho chữ giáo trình $character');
      expect(record.hasReadingFor(SupplementaryLanguage.japanese), isTrue,
          reason: 'Thiếu On\'yomi cho chữ giáo trình $character');
      expect(record.charSimplified, isNotEmpty, reason: 'Thiếu dạng giản thể (hoặc dạng dùng chung) $character');
      expect(record.charShinjitai, isNotEmpty, reason: 'Thiếu tân tự thể (hoặc dạng dùng chung) $character');
    }
    expect(byTraditional['國']?.charSimplified, '国');
    expect(byTraditional['學']?.charShinjitai, '学');
    expect(byTraditional['好']?.readingsPinyin, containsAll(['hǎo', 'hào']));
    expect(byTraditional['重']?.readingsPinyin, containsAll(['zhòng', 'chóng']));
    expect(byTraditional['長']?.readingsPinyin, containsAll(['cháng', 'zhǎng']));
  });

  test('first-run supplementary-language choice can be skipped and stays dismissed', () async {
    SharedPreferences.setMockInitialValues({
      'heartShopMigrationV2': true,
      'separateTracksV1': true,
      'thematicCurriculumV3': true,
    });
    final first = AppState();
    await first.load();
    expect(first.hasSeenSupplementaryLanguagePrompt, isFalse);
    await first.finishSupplementaryLanguagePrompt();
    expect(first.hasSeenSupplementaryLanguagePrompt, isTrue);
    first.dispose();

    final second = AppState();
    await second.load();
    expect(second.hasSeenSupplementaryLanguagePrompt, isTrue);
    expect(second.supplementaryLanguage, SupplementaryLanguage.none);
    second.dispose();
  });

  test('supplementary language setting persists without changing learner progress', () async {
    SharedPreferences.setMockInitialValues({
      'heartShopMigrationV2': true,
      'separateTracksV1': true,
      'thematicCurriculumV3': true,
      'hanLessonsCompleted': 3,
      'xp': 125,
      'gems': 220,
      'hearts': 4,
    });
    final first = AppState();
    await first.load();
    await first.setSupplementaryLanguage(SupplementaryLanguage.japanese);
    expect(first.hasSeenSupplementaryLanguagePrompt, isTrue);
    expect(first.hanLessonsCompleted, 3);
    expect(first.xp, 125);
    expect(first.gems, 220);
    expect(first.hearts, 4);
    first.dispose();

    final second = AppState();
    await second.load();
    expect(second.supplementaryLanguage, SupplementaryLanguage.japanese);
    expect(second.hasSeenSupplementaryLanguagePrompt, isTrue);
    expect(second.hanLessonsCompleted, 3);
    second.dispose();
  });
}
