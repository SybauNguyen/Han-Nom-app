import 'dart:convert';

/// Ngôn ngữ đọc bổ sung hiển thị bên cạnh âm Hán-Việt.
/// Hán-Hàn và Quảng Đông đã có chỗ trong mô hình dữ liệu nhưng chưa bật trong UI.
enum SupplementaryLanguage { none, mandarin, japanese, hanja, cantonese }

extension SupplementaryLanguageInfo on SupplementaryLanguage {
  String get label {
    switch (this) {
      case SupplementaryLanguage.none:
        return 'Không hiển thị';
      case SupplementaryLanguage.mandarin:
        return 'Quan thoại';
      case SupplementaryLanguage.japanese:
        return 'Hán-Nhật';
      case SupplementaryLanguage.hanja:
        return 'Hán-Hàn';
      case SupplementaryLanguage.cantonese:
        return 'Quảng Đông';
    }
  }

  String get readingLabel {
    switch (this) {
      case SupplementaryLanguage.none:
        return '';
      case SupplementaryLanguage.mandarin:
        return 'Pinyin';
      case SupplementaryLanguage.japanese:
        return "On'yomi";
      case SupplementaryLanguage.hanja:
        return 'Âm Hán-Hàn';
      case SupplementaryLanguage.cantonese:
        return 'Jyutping';
    }
  }

  String get characterFormLabel {
    switch (this) {
      case SupplementaryLanguage.none:
        return '';
      case SupplementaryLanguage.mandarin:
        return 'Giản thể';
      case SupplementaryLanguage.japanese:
        return 'Tân tự thể';
      case SupplementaryLanguage.hanja:
        return 'Hình thể Hán-Hàn';
      case SupplementaryLanguage.cantonese:
        return 'Chữ Hán';
    }
  }

  /// Emoji cờ dùng làm nhận diện trực quan trong onboarding và Hồ sơ.
  String get flagEmoji {
    switch (this) {
      case SupplementaryLanguage.none:
        return '🇻🇳';
      case SupplementaryLanguage.mandarin:
        return '🇨🇳';
      case SupplementaryLanguage.japanese:
        return '🇯🇵';
      case SupplementaryLanguage.hanja:
        return '🇰🇷';
      case SupplementaryLanguage.cantonese:
        return '🇭🇰';
    }
  }

  String get choiceLabel {
    switch (this) {
      case SupplementaryLanguage.none:
        return 'Chỉ Hán-Việt';
      case SupplementaryLanguage.mandarin:
        return 'Quan thoại · 简体';
      case SupplementaryLanguage.japanese:
        return 'Hán-Nhật · 日本語';
      case SupplementaryLanguage.hanja:
        return 'Hán-Hàn · 한자';
      case SupplementaryLanguage.cantonese:
        return 'Quảng Đông · 粵語';
    }
  }

  String get choiceDescription {
    switch (this) {
      case SupplementaryLanguage.none:
        return 'Giữ âm Hán-Việt làm lớp đọc duy nhất.';
      case SupplementaryLanguage.mandarin:
        return 'Hiện Pinyin và chữ giản thể Trung Quốc.';
      case SupplementaryLanguage.japanese:
        return "Hiện On'yomi và tân tự thể Nhật.";
      case SupplementaryLanguage.hanja:
        return 'Dự kiến bổ sung ở giai đoạn sau.';
      case SupplementaryLanguage.cantonese:
        return 'Dự kiến bổ sung ở giai đoạn sau.';
    }
  }
}

/// Bản ghi chữ Hán đa ngôn ngữ.
///
/// Một chữ có thể có nhiều cách đọc trong cùng một ngôn ngữ. Không dùng một
/// trường String đơn để ép các cách đọc về một giá trị duy nhất.
class CjkCharacter {
  final int? id;
  final String charTraditional;
  final String charSimplified;
  final String charShinjitai;
  final String meaningVi;
  final String? meaningEn;
  final List<String> readingsHanViet;
  final List<String> readingsPinyin;
  final List<String> readingsOnyomi;
  final List<String> readingsKunyomi;
  final List<String> readingsHanja;
  final List<String> readingsJyutping;

  const CjkCharacter({
    this.id,
    required this.charTraditional,
    required this.charSimplified,
    required this.charShinjitai,
    required this.meaningVi,
    this.meaningEn,
    required this.readingsHanViet,
    required this.readingsPinyin,
    required this.readingsOnyomi,
    required this.readingsKunyomi,
    this.readingsHanja = const [],
    this.readingsJyutping = const [],
  });

  /// Trả về hình thể chữ phù hợp với lựa chọn hiện tại.
  /// Không dùng giản thể Trung Quốc làm giá trị mặc định cho tiếng Nhật:
  /// hai hệ thống có nhiều chữ giống nhau nhưng không hoàn toàn đồng nhất.
  String getDisplayChar(SupplementaryLanguage language) {
    switch (language) {
      case SupplementaryLanguage.mandarin:
        return charSimplified.trim().isNotEmpty ? charSimplified : charTraditional;
      case SupplementaryLanguage.japanese:
        return charShinjitai.trim().isNotEmpty ? charShinjitai : charTraditional;
      case SupplementaryLanguage.none:
      case SupplementaryLanguage.hanja:
      case SupplementaryLanguage.cantonese:
        return charTraditional;
    }
  }

  List<String> getReadings(SupplementaryLanguage language) {
    switch (language) {
      case SupplementaryLanguage.none:
        return const [];
      case SupplementaryLanguage.mandarin:
        return readingsPinyin;
      case SupplementaryLanguage.japanese:
        return readingsOnyomi;
      case SupplementaryLanguage.hanja:
        return readingsHanja;
      case SupplementaryLanguage.cantonese:
        return readingsJyutping;
    }
  }

  String getPrimaryReading(SupplementaryLanguage language) {
    final readings = getReadings(language);
    return readings.isEmpty ? '' : readings.first;
  }

  bool hasReadingFor(SupplementaryLanguage language) =>
      getReadings(language).any((reading) => reading.trim().isNotEmpty);

  factory CjkCharacter.fromMap(Map<String, dynamic> map) {
    return CjkCharacter(
      id: _asInt(map['id']),
      charTraditional: _asString(map['char_traditional']),
      charSimplified: _asString(map['char_simplified']),
      charShinjitai: _asString(map['char_shinjitai']),
      meaningVi: _asString(map['meaning_vi']),
      meaningEn: _nullableString(map['meaning_en']),
      readingsHanViet: _parseList(map['readings_hanviet']),
      readingsPinyin: _parseList(map['readings_pinyin']),
      readingsOnyomi: _parseList(map['readings_onyomi']),
      readingsKunyomi: _parseList(map['readings_kunyomi']),
      readingsHanja: _parseList(map['readings_hanja']),
      readingsJyutping: _parseList(map['readings_jyutping']),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'char_traditional': charTraditional,
        'char_simplified': charSimplified,
        'char_shinjitai': charShinjitai,
        'meaning_vi': meaningVi,
        'meaning_en': meaningEn,
        'readings_hanviet': jsonEncode(readingsHanViet),
        'readings_pinyin': jsonEncode(readingsPinyin),
        'readings_onyomi': jsonEncode(readingsOnyomi),
        'readings_kunyomi': jsonEncode(readingsKunyomi),
        'readings_hanja': jsonEncode(readingsHanja),
        'readings_jyutping': jsonEncode(readingsJyutping),
      };
}

String _asString(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _asInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

List<String> _parseList(dynamic rawData) {
  if (rawData == null || rawData.toString().trim().isEmpty) return const [];
  if (rawData is List) {
    return rawData.map((value) => value.toString().trim()).where((value) => value.isNotEmpty).toList();
  }
  final raw = rawData.toString().trim();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((value) => value.toString().trim()).where((value) => value.isNotEmpty).toList();
    }
  } on FormatException {
    // Tương thích các bản JSON/SQLite cũ dùng dấu phẩy hoặc chấm phẩy.
  }
  return raw
      .replaceAll(';', ',')
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}
