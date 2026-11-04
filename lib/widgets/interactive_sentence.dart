import 'package:flutter/material.dart';

import '../data/question.dart';
import '../data/models/cjk_character.dart';

const Color _sentenceGreen = Color(0xFF28664F);
const Color _sentenceOrange = Color(0xFFCC6B3D);

/// Hiển thị từng chữ trong câu. Chạm vào chữ để xem âm Hán-Việt và nghĩa.
class InteractiveSentence extends StatelessWidget {
  final List<SentenceToken> tokens;
  final String? selectedAnswer;
  final SupplementaryLanguage supplementaryLanguage;
  final List<CjkCharacter> cjkCharacters;
  final bool tapEnabled;
  final double fontSize;

  const InteractiveSentence({
    super.key,
    required this.tokens,
    this.selectedAnswer,
    this.supplementaryLanguage = SupplementaryLanguage.none,
    this.cjkCharacters = const <CjkCharacter>[],
    this.tapEnabled = true,
    this.fontSize = 42,
  });

  CjkCharacter? _findCjkRecord(String character) {
    for (final record in cjkCharacters) {
      if (record.charTraditional == character) return record;
    }
    for (final record in cjkCharacters) {
      if (record.charSimplified == character || record.charShinjitai == character) return record;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 16,
      children: tokens.map((token) {
        if (token.isBlank) {
          return Container(
            constraints: const BoxConstraints(minWidth: 66),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _sentenceGreen, width: 2.5)),
            ),
            child: Text(
              selectedAnswer ?? '____',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontFamilyFallback: ['NomNaTong'],
                color: _sentenceGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        }

        final cjkRecord = _findCjkRecord(token.text);
        final supplementaryReadings = supplementaryLanguage == SupplementaryLanguage.none ||
                cjkRecord == null
            ? const <String>[]
            : cjkRecord.getReadings(supplementaryLanguage)
                .map((reading) => reading.trim())
                .where((reading) => reading.isNotEmpty)
                .take(supplementaryLanguage == SupplementaryLanguage.japanese ? 2 : 1)
                .toList();

        final characterText = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Text(
            token.text,
            style: TextStyle(
              fontSize: fontSize,
              fontFamilyFallback: const ['NomNaTong'],
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              decoration: tapEnabled ? TextDecoration.underline : TextDecoration.none,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: Colors.grey,
              decorationThickness: 2,
            ),
          ),
        );
        if (!tapEnabled) return characterText;

        return Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 3),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE5DD)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          richMessage: TextSpan(children: [
            TextSpan(
              text: '${token.hanVietReading?.toUpperCase() ?? ''}\\n',
              style: const TextStyle(color: _sentenceOrange, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text: token.meaning ?? '',
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            if (supplementaryReadings.isNotEmpty)
              TextSpan(
                text: '\\n${supplementaryLanguage.label}: ${supplementaryReadings.join(' · ')}',
                style: const TextStyle(color: _sentenceGreen, fontSize: 14, fontWeight: FontWeight.w800),
              ),
          ]),
          child: characterText,
        );
      }).toList(),
    );
  }
}
