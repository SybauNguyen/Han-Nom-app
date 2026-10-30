import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/dictionary_search.dart';
import '../../data/han_character.dart';
import '../../data/han_seed_data.dart';
import '../../data/legacy_nom_codepoints.dart';
import '../../data/models/cjk_character.dart';

class DatabaseService {
  Database? _db;
  Future<void>? _initializing;
  String? lastImportError;
  String? lastCjkImportError;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final root = await databaseFactory.getDatabasesPath();
    final path = p.join(root, 'han_viet_duo_catalogue.db');
    _db = await openDatabase(
      path,
      // Version 5 adds a separate CJKV reading table. Existing lesson data,
      // mastery and app preferences are preserved by an additive migration.
      version: 5,
      onCreate: (db, version) => _ensureSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureSchema(db);
      },
    );
    await _seedCurriculum();
    await _loadMassiveDictionary();
    await _loadCjkDictionary();
    if (!isNomDataEnabled) await _purgeNomRecords();
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character TEXT NOT NULL DEFAULT '' UNIQUE,
        han_viet_reading TEXT NOT NULL DEFAULT '',
        meaning TEXT NOT NULL DEFAULT '',
        radical TEXT NOT NULL DEFAULT '',
        structure TEXT NOT NULL DEFAULT 'Chưa rõ',
        difficulty INTEGER NOT NULL DEFAULT 3,
        mastery INTEGER NOT NULL DEFAULT 0,
        examples_json TEXT NOT NULL DEFAULT '[]',
        mnemonic TEXT,
        type TEXT NOT NULL DEFAULT 'Hán',
        in_curriculum INTEGER NOT NULL DEFAULT 0,
        curriculum_order INTEGER,
        reading_folded TEXT NOT NULL DEFAULT '',
        meaning_folded TEXT NOT NULL DEFAULT '',
        radical_folded TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Upgrade databases created by earlier builds without deleting the table.
    final tableInfo = await db.rawQuery('PRAGMA table_info(characters)');
    final columns = tableInfo.map((row) => row['name']?.toString()).whereType<String>().toSet();
    const additions = <String, String>{
      'character': "TEXT NOT NULL DEFAULT ''",
      'han_viet_reading': "TEXT NOT NULL DEFAULT ''",
      'meaning': "TEXT NOT NULL DEFAULT ''",
      'radical': "TEXT NOT NULL DEFAULT ''",
      'structure': "TEXT NOT NULL DEFAULT 'Chưa rõ'",
      'difficulty': 'INTEGER NOT NULL DEFAULT 3',
      'mastery': 'INTEGER NOT NULL DEFAULT 0',
      'examples_json': "TEXT NOT NULL DEFAULT '[]'",
      'mnemonic': 'TEXT',
      'type': "TEXT NOT NULL DEFAULT 'Hán'",
      'in_curriculum': 'INTEGER NOT NULL DEFAULT 0',
      'curriculum_order': 'INTEGER',
      'reading_folded': "TEXT NOT NULL DEFAULT ''",
      'meaning_folded': "TEXT NOT NULL DEFAULT ''",
      'radical_folded': "TEXT NOT NULL DEFAULT ''",
    };
    for (final entry in additions.entries) {
      if (!columns.contains(entry.key)) {
        await db.execute('ALTER TABLE characters ADD COLUMN ${entry.key} ${entry.value}');
      }
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // CJKV metadata is separate from the learning catalogue: updating readings
    // must never overwrite character mastery or lesson progress.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cjk_characters (
        id INTEGER PRIMARY KEY,
        char_traditional TEXT NOT NULL UNIQUE,
        char_simplified TEXT NOT NULL DEFAULT '',
        char_shinjitai TEXT NOT NULL DEFAULT '',
        meaning_vi TEXT NOT NULL DEFAULT '',
        meaning_en TEXT,
        readings_hanviet TEXT NOT NULL DEFAULT '[]',
        readings_pinyin TEXT NOT NULL DEFAULT '[]',
        readings_onyomi TEXT NOT NULL DEFAULT '[]',
        readings_kunyomi TEXT NOT NULL DEFAULT '[]',
        readings_hanja TEXT NOT NULL DEFAULT '[]',
        readings_jyutping TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cjk_simplified ON cjk_characters(char_simplified)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cjk_shinjitai ON cjk_characters(char_shinjitai)');

    // Clean invalid keys and merge any legacy duplicate rows, keeping the best
    // mastery level before creating a unique index.
    await db.execute("DELETE FROM characters WHERE character IS NULL OR TRIM(character) = ''");
    await db.execute('''
      UPDATE characters
      SET mastery = COALESCE((
        SELECT MAX(other.mastery)
        FROM characters AS other
        WHERE other.character = characters.character
      ), 0)
      WHERE character IS NOT NULL
    ''');
    await db.execute('''
      DELETE FROM characters
      WHERE id NOT IN (
        SELECT MIN(id) FROM characters GROUP BY character
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_characters_character_unique ON characters(character)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_characters_type_curriculum ON characters(type, in_curriculum, curriculum_order)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_characters_reading_folded ON characters(reading_folded)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_characters_meaning_folded ON characters(meaning_folded)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_characters_radical_folded ON characters(radical_folded)');

    // Backfill accent-insensitive search columns on legacy rows after migration.
    final legacyRows = await db.query('characters', columns: ['id', 'han_viet_reading', 'meaning', 'radical']);
    final batch = db.batch();
    for (final row in legacyRows) {
      batch.update(
        'characters',
        {
          'reading_folded': _fold(row['han_viet_reading']?.toString() ?? ''),
          'meaning_folded': _fold(row['meaning']?.toString() ?? ''),
          'radical_folded': _fold(row['radical']?.toString() ?? ''),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    if (legacyRows.isNotEmpty) await batch.commit(noResult: true);
  }

  Future<Database> get _database async {
    // During first initialization, _seedCurriculum/_loadMassiveDictionary may
    // call this getter themselves. Return the already-open handle to avoid a
    // future waiting on its own initialization future.
    if (_db != null) return _db!;
    await initialize();
    return _db!;
  }

  String _fold(String value) => foldVietnameseForSearch(value);

  Map<String, Object?> _rowFor(HanCharacter character, {
    required bool inCurriculum,
    int? curriculumOrder,
    bool includeMastery = true,
  }) {
    final row = character.toDatabaseMap(curriculumOverride: inCurriculum);
    row.remove('id');
    if (!includeMastery) row.remove('mastery');
    row['curriculum_order'] = curriculumOrder;
    row['reading_folded'] = _fold(character.hanVietReading);
    row['meaning_folded'] = _fold(character.meaning);
    row['radical_folded'] = _fold(character.radical);
    return row;
  }

  Map<String, Object?>? _parseDictionaryItem(Map<String, dynamic> item) {
    final character = HanCharacter.fromDictionaryMap(item, inCurriculum: false);
    if (!isNomDataEnabled && (character.isNom || retiredNomCodepoints.contains(character.character))) return null;
    return _rowFor(character, inCurriculum: false);
  }

  Future<void> _purgeNomRecords() async {
    final db = await _database;
    // SQLite lower/upper mặc định không chuẩn hóa đầy đủ chữ cái tiếng Việt có dấu,
    // vì vậy so sánh trực tiếp các nhãn cũ và mã Unicode Nôm đã nghỉ dùng.
    final retired = retiredNomCodepoints.toList(growable: false);
    final placeholders = List<String>.filled(retired.length, '?').join(',');
    await db.delete(
      'characters',
      where: "TRIM(type) IN ('Nôm','NÔM','nôm','NôM','NOM','Nom','nom','Chữ Nôm','chữ nôm','Chu Nom','chu nom') OR character IN ($placeholders)",
      whereArgs: retired,
    );
    final remainingDictionaryRows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM characters WHERE in_curriculum = 0',
    );
    final remainingCount = (remainingDictionaryRows.first['count'] as num?)?.toInt() ?? 0;
    // Keep the import-count checksum in sync with the deliberate cleanup above.
    await db.insert(
      'app_metadata',
      {'key': 'dictionary_imported_count', 'value': remainingCount.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _seedCurriculum() async {
    final db = await _database;
    final orderByCharacter = <String, int>{};
    var cursor = 0;
    for (final unit in lessonUnits) {
      for (final character in unit.characters) {
        orderByCharacter.putIfAbsent(character, () => cursor++);
      }
    }
    await db.transaction((txn) async {
      // Reconcile curriculum membership to the current seed. This does not
      // delete characters or change mastery; removed seed entries become
      // dictionary-only rather than remaining in an obsolete lesson path.
      await txn.update('characters', {'in_curriculum': 0, 'curriculum_order': null});
      final batch = txn.batch();
      for (final character in seedCharacters) {
        final order = orderByCharacter[character.character];
        batch.insert(
          'characters',
          _rowFor(character, inCurriculum: true, curriculumOrder: order),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      // If a future curriculum character used to exist as dictionary-only, promote
      // it without resetting its mastery counter.
      for (final character in seedCharacters) {
        final row = _rowFor(
          character,
          inCurriculum: true,
          curriculumOrder: orderByCharacter[character.character],
          includeMastery: false,
        );
        await txn.update('characters', row, where: 'character = ?', whereArgs: [character.character]);
      }
    });
  }

  Future<void> _loadMassiveDictionary() async {
    final db = await _database;
    try {
      // A full app restart/rebuild is required for Flutter to bundle a changed
      // asset. Once bundled, SHA-256 detects new JSON without destructive DB resets.
      final raw = await rootBundle.loadString('assets/data/dictionary.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('dictionary.json phải là một mảng JSON.');
      final assetHash = crypto.sha256.convert(utf8.encode(raw)).toString();

      // Parse first; if the asset is malformed, keep the last working dictionary.
      final rows = <Map<String, Object?>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final row = _parseDictionaryItem(Map<String, dynamic>.from(item));
          if (row != null) rows.add(row);
        } catch (_) {
          // One malformed optional record must not stop the catalogue import.
        }
      }

      final storedHashRows = await db.query(
        'app_metadata', columns: ['value'], where: 'key = ?', whereArgs: ['dictionary_asset_sha256'], limit: 1,
      );
      final storedCountRows = await db.query(
        'app_metadata', columns: ['value'], where: 'key = ?', whereArgs: ['dictionary_imported_count'], limit: 1,
      );
      final actualCountRows = await db.rawQuery('SELECT COUNT(*) AS count FROM characters WHERE in_curriculum = 0');
      final actualCount = (actualCountRows.first['count'] as num?)?.toInt() ?? 0;
      final storedHash = storedHashRows.isEmpty ? null : storedHashRows.first['value']?.toString();
      final storedCount = storedCountRows.isEmpty ? -1 : int.tryParse(storedCountRows.first['value']?.toString() ?? '') ?? -1;
      if (storedHash == assetHash && storedCount == actualCount) {
        lastImportError = null;
        return;
      }

      // Replace only dictionary-only records. Curriculum and mastery persist.
      await db.transaction((txn) async {
        await txn.delete('characters', where: 'in_curriculum = 0');
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert('characters', row, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);

        final importedCountRows = await txn.rawQuery('SELECT COUNT(*) AS count FROM characters WHERE in_curriculum = 0');
        final importedCount = (importedCountRows.first['count'] as num?)?.toInt() ?? 0;
        await txn.insert('app_metadata', {'key': 'dictionary_asset_sha256', 'value': assetHash}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('app_metadata', {'key': 'dictionary_imported_count', 'value': importedCount.toString()}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('app_metadata', {'key': 'dictionary_imported_at_utc', 'value': DateTime.now().toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      lastImportError = null;
    } catch (error) {
      // Keep the curriculum and last working dictionary usable if the asset is
      // absent or malformed; diagnostics are available to the app.
      lastImportError = error.toString();
    }
  }

  Future<void> _loadCjkDictionary() async {
    final db = await _database;
    try {
      final raw = await rootBundle.loadString('assets/data/master_dictionary.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('master_dictionary.json phải là một mảng JSON.');
      }
      final assetHash = crypto.sha256.convert(utf8.encode(raw)).toString();
      final records = <Map<String, Object?>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final character = CjkCharacter.fromMap(Map<String, dynamic>.from(item));
          if (character.charTraditional.trim().isEmpty) continue;
          records.add(character.toMap());
        } catch (_) {
          // Bỏ qua bản ghi đa ngôn ngữ lỗi riêng lẻ, không chặn app.
        }
      }
      final hashRows = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['cjk_dictionary_asset_sha256'],
        limit: 1,
      );
      final countRows = await db.rawQuery('SELECT COUNT(*) AS count FROM cjk_characters');
      final actualCount = (countRows.first['count'] as num?)?.toInt() ?? 0;
      final storedHash = hashRows.isEmpty ? null : hashRows.first['value']?.toString();
      if (storedHash == assetHash && actualCount == records.length) {
        lastCjkImportError = null;
        return;
      }

      // This table stores reference readings only, not learner progress. It is
      // safe to replace its rows transactionally when the asset changes.
      await db.transaction((txn) async {
        await txn.delete('cjk_characters');
        final batch = txn.batch();
        for (final row in records) {
          batch.insert('cjk_characters', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
        await txn.insert(
          'app_metadata',
          {'key': 'cjk_dictionary_asset_sha256', 'value': assetHash},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          'app_metadata',
          {'key': 'cjk_dictionary_imported_count', 'value': records.length.toString()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          'app_metadata',
          {'key': 'cjk_dictionary_imported_at_utc', 'value': DateTime.now().toUtc().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      lastCjkImportError = null;
    } catch (error) {
      // A missing/broken supplementary file must not break the original v2.6 app.
      lastCjkImportError = error.toString();
    }
  }

  Future<CjkCharacter?> getCjkCharacter(String character) async {
    final query = character.trim();
    if (query.isEmpty) return null;
    final db = await _database;
    final rows = await db.query(
      'cjk_characters',
      where: 'char_traditional = ? OR char_simplified = ? OR char_shinjitai = ?',
      whereArgs: [query, query, query],
      orderBy: 'id ASC',
      limit: 20,
    );
    if (rows.isEmpty) return null;
    final characters = rows.map((row) => CjkCharacter.fromMap(Map<String, dynamic>.from(row))).toList();
    for (final item in characters) {
      if (item.charTraditional == query) return item;
    }
    for (final item in characters) {
      if (item.charSimplified == query || item.charShinjitai == query) return item;
    }
    return characters.first;
  }

  Future<List<CjkCharacter>> getCjkCharacters({int limit = 100, int offset = 0}) async {
    final db = await _database;
    final safeLimit = limit.clamp(1, 1000).toInt();
    final result = await db.query(
      'cjk_characters',
      orderBy: 'id ASC',
      limit: safeLimit,
      offset: offset < 0 ? 0 : offset,
    );
    return result.map((row) => CjkCharacter.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<int> countDictionary({String? type, bool? inCurriculum, String? query}) async {
    final db = await _database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null && type != 'Tất cả') { where.add('type = ?'); args.add(type); }
    if (inCurriculum != null) { where.add('in_curriculum = ?'); args.add(inCurriculum ? 1 : 0); }
    final trimmed = query?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      final normalized = _fold(trimmed);
      where.add('(character LIKE ? OR reading_folded LIKE ? OR meaning_folded LIKE ? OR radical_folded LIKE ? OR examples_json LIKE ?)');
      args.addAll(['%$trimmed%', '%$normalized%', '%$normalized%', '%$normalized%', '%$trimmed%']);
    }
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM characters${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}',
      args,
    );
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<List<HanCharacter>> searchDictionary(
    String query, {
    String? type,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _database;
    final normalized = _fold(query.trim());
    final clauses = <String>[];
    final args = <Object?>[];
    if (normalized.isNotEmpty) {
      clauses.add('(character LIKE ? OR reading_folded LIKE ? OR meaning_folded LIKE ? OR radical_folded LIKE ? OR examples_json LIKE ?)');
      args.addAll(['%${query.trim()}%', '%$normalized%', '%$normalized%', '%$normalized%', '%${query.trim()}%']);
    }
    if (type != null && type != 'Tất cả') {
      clauses.add('type = ?');
      args.add(type);
    }
    final whereSql = clauses.isEmpty ? '' : ' WHERE ${clauses.join(' AND ')}';
    final safeLimit = limit.clamp(1, 500).toInt();
    if (normalized.isNotEmpty) {
      final sortedRows = await db.rawQuery(
        'SELECT * FROM characters$whereSql ORDER BY CASE WHEN character = ? THEN 0 WHEN reading_folded = ? THEN 1 WHEN meaning_folded = ? THEN 2 ELSE 3 END, in_curriculum DESC, COALESCE(curriculum_order, 999999) ASC, han_viet_reading COLLATE NOCASE ASC LIMIT ? OFFSET ?',
        <Object?>[...args, query.trim(), normalized, normalized, safeLimit, offset],
      );
      return sortedRows.map(HanCharacter.fromDatabaseMap).toList();
    }
    final rows = await db.query(
      'characters',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: clauses.isEmpty ? null : args,
      orderBy: 'in_curriculum DESC, COALESCE(curriculum_order, 999999) ASC, han_viet_reading COLLATE NOCASE ASC',
      limit: safeLimit,
      offset: offset,
    );
    return rows.map(HanCharacter.fromDatabaseMap).toList();
  }

  Future<List<HanCharacter>> getCurriculumCharacters({required String type}) async {
    final db = await _database;
    final rows = await db.query(
      'characters',
      where: 'type = ? AND in_curriculum = 1',
      whereArgs: [type],
      orderBy: 'curriculum_order ASC',
    );
    return rows.map(HanCharacter.fromDatabaseMap).toList();
  }

  Future<List<HanCharacter>> getCharactersForLesson({required String type, required int lessonNumber}) async {
    if (lessonNumber < 1) return <HanCharacter>[];
    final units = type == 'Nôm' ? nomLessonUnits : hanLessonUnits;
    if (lessonNumber > units.length) return <HanCharacter>[];
    final symbols = units[lessonNumber - 1].characters;
    if (symbols.isEmpty) return <HanCharacter>[];
    final db = await _database;
    final uniqueSymbols = symbols.toSet().toList();
    final placeholders = List<String>.filled(uniqueSymbols.length, '?').join(',');
    final rows = await db.query(
      'characters',
      where: 'character IN ($placeholders)',
      whereArgs: uniqueSymbols,
    );
    final bySymbol = <String, HanCharacter>{
      for (final row in rows) row['character']!.toString(): HanCharacter.fromDatabaseMap(row),
    };
    // Restore Node order. This also preserves the one intentional review item
    // on the final Nôm Node without creating a duplicate DB record.
    return symbols.map((symbol) => bySymbol[symbol]).whereType<HanCharacter>().toList();
  }

  Future<List<HanCharacter>> getHanReviewCharacters(int checkpointNumber, {int limit = 20}) async {
    if (checkpointNumber < 1 || limit < 1) return <HanCharacter>[];
    final db = await _database;
    final rows = await db.query(
      'characters',
      where: "type = 'Hán' AND in_curriculum = 1",
      orderBy: 'curriculum_order ASC',
      limit: 50,
      offset: (checkpointNumber - 1) * 50,
    );
    final pool = rows.map(HanCharacter.fromDatabaseMap).toList()..shuffle(Random());
    return pool.take(min(limit, pool.length)).toList();
  }

  Future<List<HanCharacter>> getJumpAheadCharacters({int targetLessonNumber = 1, int limit = 10, String type = 'Hán'}) async {
    if (targetLessonNumber <= 1 || targetLessonNumber > hanCoreLessonCount || limit < 1) return <HanCharacter>[];
    final db = await _database;
    final targetOffset = (targetLessonNumber - 1) * 10;
    final pastRows = await db.query(
      'characters', where: 'type = ? AND in_curriculum = 1',
      whereArgs: [type], orderBy: 'curriculum_order ASC', limit: targetOffset,
    );
    final pool = pastRows.map(HanCharacter.fromDatabaseMap).toList()..shuffle(Random());
    // Tuyệt đối không bù bằng chữ thuộc bài hiện tại hoặc tương lai.
    return pool.take(min(limit, pool.length)).toList();
  }
}
