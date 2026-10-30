import 'han_character.dart';

/// Chuẩn hóa chuỗi để người học có thể tìm tiếng Việt có hoặc không có dấu.
String foldVietnameseForSearch(String input) {
  var value = input.toLowerCase().replaceAll('đ', 'd');
  const groups = <String, String>{
    'a': 'áàảãạăắằẳẵặâấầẩẫậ',
    'e': 'éèẻẽẹêếềểễệ',
    'i': 'íìỉĩị',
    'o': 'óòỏõọôốồổỗộơớờởỡợ',
    'u': 'úùủũụưứừửữự',
    'y': 'ýỳỷỹỵ',
  };
  for (final entry in groups.entries) {
    for (final char in entry.value.split('')) {
      value = value.replaceAll(char, entry.key);
    }
  }
  return value;
}

/// Tìm theo Hán tự, âm Hán-Việt, nghĩa, bộ thủ và từ ghép.
/// Những kết quả khớp đầu từ được ưu tiên trước các kết quả khớp một phần.
List<HanCharacter> searchHanCharacters(
  Iterable<HanCharacter> source,
  String query,
) {
  final normalizedQuery = foldVietnameseForSearch(query.trim());
  final characters = source.toList();
  if (normalizedQuery.isEmpty) return characters;

  final matches = characters.where((character) {
    final fields = <String>[
      character.character,
      character.hanVietReading,
      character.meaning,
      character.radical,
      character.type,
      ...character.examples,
    ].map(foldVietnameseForSearch);
    return fields.any((field) => field.contains(normalizedQuery));
  }).toList();

  int score(HanCharacter character) {
    final reading = foldVietnameseForSearch(character.hanVietReading);
    final meaning = foldVietnameseForSearch(character.meaning);
    final radical = foldVietnameseForSearch(character.radical);
    if (character.character == normalizedQuery || reading == normalizedQuery || meaning == normalizedQuery || radical == normalizedQuery) {
      return 0;
    }
    if (reading.startsWith(normalizedQuery) || meaning.startsWith(normalizedQuery) || radical.startsWith(normalizedQuery)) {
      return 1;
    }
    return 2;
  }

  matches.sort((a, b) {
    final scoreOrder = score(a).compareTo(score(b));
    if (scoreOrder != 0) return scoreOrder;
    final readingOrder = a.hanVietReading.compareTo(b.hanVietReading);
    if (readingOrder != 0) return readingOrder;
    return a.character.compareTo(b.character);
  });
  return matches;
}
