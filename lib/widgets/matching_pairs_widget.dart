import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

const Color _matchGreen = Color(0xFF28664F);
const Color _matchGreenLight = Color(0xFFE4F1E8);
const Color _matchBlue = Color(0xFF3186C8);
const Color _matchRed = Color(0xFFD94343);

/// Bài nối cặp hai cột. Mỗi cặp được giữ bằng chỉ số, vì vậy vẫn hoạt động
/// chính xác nếu nhiều chữ có cùng nghĩa hiển thị.
class MatchingPairsWidget extends StatefulWidget {
  final Map<String, String> pairs;
  final VoidCallback onComplete;
  final VoidCallback? onMistake;
  final bool enabled;

  const MatchingPairsWidget({
    super.key,
    required this.pairs,
    required this.onComplete,
    this.onMistake,
    this.enabled = true,
  });

  @override
  State<MatchingPairsWidget> createState() => _MatchingPairsWidgetState();
}

class _MatchingPairsWidgetState extends State<MatchingPairsWidget> {
  late final List<MapEntry<String, String>> _entries;
  late final List<int> _leftOrder;
  late final List<int> _rightOrder;
  final Set<int> _solved = <int>{};
  int? _selectedLeft;
  int? _selectedRight;
  int? _wrongLeft;
  int? _wrongRight;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.pairs.entries.toList();
    _leftOrder = List<int>.generate(_entries.length, (index) => index)..shuffle(Random());
    _rightOrder = List<int>.generate(_entries.length, (index) => index)..shuffle(Random());
  }

  void _onTap(int pairIndex, {required bool left}) {
    if (!widget.enabled || _solved.contains(pairIndex)) return;
    var completed = false;
    var mismatch = false;
    int? wrongLeft;
    int? wrongRight;

    setState(() {
      if (left) {
        _selectedLeft = _selectedLeft == pairIndex ? null : pairIndex;
      } else {
        _selectedRight = _selectedRight == pairIndex ? null : pairIndex;
      }

      if (_selectedLeft != null && _selectedRight != null) {
        if (_selectedLeft == _selectedRight) {
          _solved.add(_selectedLeft!);
          completed = _solved.length == _entries.length;
          _selectedLeft = null;
          _selectedRight = null;
        } else {
          mismatch = true;
          wrongLeft = _selectedLeft;
          wrongRight = _selectedRight;
          _wrongLeft = wrongLeft;
          _wrongRight = wrongRight;
          _selectedLeft = null;
          _selectedRight = null;
        }
      }
    });

    if (mismatch) {
      widget.onMistake?.call();
      unawaited(Future<void>.delayed(const Duration(milliseconds: 520)).then((_) {
        if (!mounted) return;
        setState(() {
          if (_wrongLeft == wrongLeft) _wrongLeft = null;
          if (_wrongRight == wrongRight) _wrongRight = null;
        });
      }));
    }

    if (completed && !_completionSent) {
      _completionSent = true;
      widget.onComplete();
    }
  }

  Widget _buildTile(int pairIndex, {required bool left}) {
    final solved = _solved.contains(pairIndex);
    if (solved) return const SizedBox(height: 66);

    final selected = left ? _selectedLeft == pairIndex : _selectedRight == pairIndex;
    final wrong = left ? _wrongLeft == pairIndex : _wrongRight == pairIndex;
    final label = left ? _entries[pairIndex].key : _entries[pairIndex].value;
    final background = wrong
        ? const Color(0xFFFFE9E7)
        : selected
            ? _matchBlue.withOpacity(0.12)
            : Colors.white;
    final borderColor = wrong
        ? _matchRed
        : selected
            ? _matchBlue
            : const Color(0xFFDCE4DC);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.enabled ? () => _onTap(pairIndex, left: left) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: selected || wrong ? 2 : 1.5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: left ? 23 : 14,
                fontWeight: FontWeight.w800,
                color: wrong ? _matchRed : selected ? _matchBlue : const Color(0xFF263A2F),
                fontFamilyFallback: left ? const ['NomNaTong', 'HanNomB'] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return const Center(child: Text('Bài nối cặp chưa có dữ liệu.'));
    }

    return Column(
      children: [
        const Text(
          'CHỌN MỘT CHỮ, SAU ĐÓ CHỌN NGHĨA TƯƠNG ỨNG',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: _matchGreen, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: _leftOrder.map((index) => _buildTile(index, left: true)).toList())),
            const SizedBox(width: 10),
            Expanded(child: Column(children: _rightOrder.map((index) => _buildTile(index, left: false)).toList())),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 17, color: _matchGreen),
            const SizedBox(width: 6),
            Text('${_solved.length}/${_entries.length} cặp đã nối', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _matchGreen)),
          ],
        ),
      ],
    );
  }
}
