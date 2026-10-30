import 'package:flutter/material.dart';

import '../data/question.dart';
import 'interactive_sentence.dart';

const Color _blankGreen = Color(0xFF28664F);
const Color _blankRed = Color(0xFFD94343);

/// Bài điền khuyết: xem tooltip trên các chữ, sau đó chạm chọn chữ còn thiếu.
class FillInTheBlankWidget extends StatelessWidget {
  final List<SentenceToken> tokens;
  final List<String> options;
  final String? selectedAnswer;
  final String correctAnswer;
  final bool checked;
  final bool isCorrect;
  final ValueChanged<String> onSelected;

  const FillInTheBlankWidget({
    super.key,
    required this.tokens,
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.checked,
    required this.isCorrect,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(color: const Color(0xFFE4F1E8), borderRadius: BorderRadius.circular(22)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.touch_app_rounded, color: _blankGreen, size: 18),
              SizedBox(width: 6),
              Flexible(child: Text('CHẠM VÀO CHỮ ĐỂ XEM NGHĨA', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, letterSpacing: 0.7, color: _blankGreen, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 18),
            InteractiveSentence(tokens: tokens, selectedAnswer: selectedAnswer),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('CHỌN CHỮ CÒN THIẾU', style: TextStyle(fontSize: 11, letterSpacing: 1, color: Colors.black45, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = selectedAnswer == option;
            final isRight = option == correctAnswer;
            final background = checked && isRight
                ? const Color(0xFFE4F5E8)
                : checked && selected && !isCorrect
                    ? const Color(0xFFFFE9E7)
                    : selected
                        ? const Color(0xFFEAF2FF)
                        : Colors.white;
            final border = checked && isRight
                ? _blankGreen
                : checked && selected && !isCorrect
                    ? _blankRed
                    : selected
                        ? const Color(0xFF3186C8)
                        : const Color(0xFFDCE4DC);
            return Semantics(
              button: true,
              selected: selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: checked ? null : () => onSelected(option),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 58, minHeight: 54),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13), border: Border.all(color: border, width: 1.7)),
                  child: Text(option, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: checked && isRight ? _blankGreen : const Color(0xFF263A2F), fontFamilyFallback: const ['NomNaTong', 'HanNomB'])),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
