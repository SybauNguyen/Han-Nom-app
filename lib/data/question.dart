enum QuestionType {
  introduceWord,
  reading,
  meaning,
  character,
  fillInTheBlank,
  radical,
  typing,
  typingSentenceMeaning, // Legacy compatibility: older sentence-meaning questions.
  typingSentenceReading, // Type the Hán-Việt reading; show Vietnamese gloss after checking.
  matchingPairs,
  translateSentence,
  translateHanVietToCharacter,
}

class SentenceToken {
  final String text;
  final String? hanVietReading;
  final String? meaning;
  final bool isBlank;

  const SentenceToken({
    required this.text,
    this.hanVietReading,
    this.meaning,
    this.isBlank = false,
  });
}

class Question {
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String associatedCharacter;
  final List<SentenceToken>? sentenceTokens;
  final String sectionTitle;
  final List<String>? acceptedAnswers;
  final String? mnemonic;
  /// Văn bản nguồn hiển thị trên câu hỏi: âm Hán-Việt khi dịch ngược hoặc
  /// chữ Hán khi luyện đọc/gõ âm Hán-Việt của câu.
  final String? sourceText;
  /// Nghĩa tiếng Việt tham khảo, chỉ hiện sau khi người học nộp câu trả lời.
  final String? meaningExplanation;
  /// Dùng để tô nhãn xanh cho Hán tự và cam cho chữ Nôm.
  final String characterType;
  /// Cặp Hán tự -> âm Hán-Việt và nghĩa, dùng cho bài nối cặp.
  final Map<String, String>? matchingPairs;

  const Question({
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.associatedCharacter,
    this.sentenceTokens,
    this.sectionTitle = 'Bài học',
    this.acceptedAnswers,
    this.mnemonic,
    this.sourceText,
    this.meaningExplanation,
    this.characterType = 'Hán',
    this.matchingPairs,
  });

  String get answer => correctAnswer;
  String get character => associatedCharacter;
}
