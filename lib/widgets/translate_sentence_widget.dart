import 'dart:math';

import 'package:flutter/material.dart';

import '../data/question.dart';
import 'interactive_sentence.dart';

const Color _translateGreen = Color(0xFF28664F);
const Color _translateBlue = Color(0xFF3186C8);

/// Người học có thể chạm hoặc kéo các mảnh nghĩa để xếp thành bản dịch;
/// kéo/chạm lại vào mảnh trong dòng trả lời để trả nó về ngân hàng từ.
class TranslateSentenceWidget extends StatefulWidget {
  final Question question;
  final ValueChanged<String> onAnswerChanged;
  final bool enabled;
  /// true khi đề bài là âm Hán-Việt và đáp án cần ghép là chữ Hán.
  final bool reverseDirection;

  const TranslateSentenceWidget({
    super.key,
    required this.question,
    required this.onAnswerChanged,
    this.enabled = true,
    this.reverseDirection = false,
  });

  @override
  State<TranslateSentenceWidget> createState() => _TranslateSentenceWidgetState();
}

class _TranslateSentenceWidgetState extends State<TranslateSentenceWidget> {
  late List<int> _available;
  final List<int> _selected = <int>[];

  @override
  void initState() {
    super.initState();
    _resetWords();
  }

  @override
  void didUpdateWidget(covariant TranslateSentenceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) _resetWords();
  }

  void _resetWords() {
    _available = List<int>.generate(widget.question.options.length, (index) => index)..shuffle(Random());
    _selected.clear();
  }

  void _emitAnswer() {
    widget.onAnswerChanged(_selected.map((index) => widget.question.options[index]).join(' '));
  }

  void _choose(int index) {
    if (!widget.enabled || !_available.contains(index)) return;
    setState(() {
      _available.remove(index);
      _selected.add(index);
    });
    _emitAnswer();
  }

  void _remove(int index) {
    if (!widget.enabled || !_selected.contains(index)) return;
    setState(() {
      _selected.remove(index);
      _available.add(index);
    });
    _emitAnswer();
  }

  Widget _wordTile(int index, {required bool selected}) {
    final word = widget.question.options[index];
    final tile = Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: selected ? const Color(0xFFEAF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.enabled ? () => selected ? _remove(index) : _choose(index) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? _translateBlue : const Color(0xFFDCE4DC), width: 1.5),
              boxShadow: selected ? const [] : const [BoxShadow(color: Color(0x16000000), offset: Offset(0, 2), blurRadius: 2)],
            ),
            alignment: Alignment.center,
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.reverseDirection ? 25 : 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF263A2F),
                fontFamilyFallback: widget.reverseDirection ? const ['NomNaTong', 'HanNomB'] : null,
              ),
            ),
          ),
        ),
      ),
    );

    // Draggable giữ thao tác chạm cho điện thoại nhưng cũng hỗ trợ kéo thả
    // bằng chuột trên web/desktop.
    return Draggable<int>(
      data: index,
      maxSimultaneousDrags: widget.enabled ? 1 : 0,
      feedback: Material(
        elevation: 6,
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.reverseDirection ? 25 : 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF263A2F),
                fontFamilyFallback: widget.reverseDirection ? const ['NomNaTong', 'HanNomB'] : null,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFE4F1E8), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.touch_app_rounded, color: _translateGreen, size: 18),
                const SizedBox(width: 6),
                Flexible(child: Text(
                  widget.reverseDirection
                      ? 'ĐỌC ÂM HÁN-VIỆT, GHÉP CÁC CHỮ HÁN TƯƠNG ỨNG'
                      : 'CHẠM VÀO CHỮ ĐỂ XEM ÂM VÀ NGHĨA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, letterSpacing: 0.7, color: _translateGreen, fontWeight: FontWeight.w900),
                )),
              ]),
              const SizedBox(height: 17),
              if (widget.reverseDirection)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.question.sourceText ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _translateGreen, height: 1.4),
                  ),
                )
              else
                InteractiveSentence(tokens: widget.question.sentenceTokens ?? const <SentenceToken>[]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(widget.reverseDirection ? 'CHỮ HÁN CỦA BẠN' : 'ÂM HÁN-VIỆT CỦA BẠN', style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: Colors.black45, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        DragTarget<int>(
          onWillAccept: (_) => widget.enabled,
          onAccept: _choose,
          builder: (context, candidateData, rejectedData) => Container(
            constraints: const BoxConstraints(minHeight: 64),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? const Color(0xFFEAF2FF) : Colors.transparent,
              border: const Border(bottom: BorderSide(color: Color(0xFFBFCBC0), width: 2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: _selected.map((index) => _wordTile(index, selected: true)).toList(),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(widget.reverseDirection ? 'NGÂN HÀNG CHỮ HÁN' : 'NGÂN HÀNG ÂM HÁN-VIỆT', style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: Colors.black45, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        DragTarget<int>(
          onWillAccept: (_) => widget.enabled,
          onAccept: _remove,
          builder: (context, candidateData, rejectedData) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? const Color(0xFFF0F4F0) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: _available.map((index) => _wordTile(index, selected: false)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
