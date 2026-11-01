import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../state/app_state.dart';

class MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const MiniStat({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDE8)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class HeartCountdownText extends StatefulWidget {
  final AppState appState;
  final TextStyle? style;
  const HeartCountdownText({super.key, required this.appState, this.style});

  @override
  State<HeartCountdownText> createState() => _HeartCountdownTextState();
}

class _HeartCountdownTextState extends State<HeartCountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final remaining = widget.appState.heartRegenSecondsRemaining;
    if (remaining == null) return '';
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appState.hearts >= AppState.maxHearts) {
      return Text('Đầy tim', style: widget.style);
    }
    return Text(_formatCountdown(), style: widget.style, semanticsLabel: 'Thời gian hồi tim còn lại ${_formatCountdown()}');
  }
}

class HeartMiniStat extends StatelessWidget {
  final AppState appState;
  const HeartMiniStat({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDE8)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.favorite_rounded, color: kRed, size: 23),
            const SizedBox(width: 5),
            Text('${appState.hearts}/5', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            const Text('Tim', style: TextStyle(fontSize: 11, color: Colors.black54)),
            if (appState.hearts < AppState.maxHearts) ...[
              const SizedBox(width: 4),
              Flexible(child: HeartCountdownText(appState: appState, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w800))),
            ],
          ]),
        ],
      ),
    );
  }
}

class HeartAppBarStatus extends StatelessWidget {
  final AppState appState;
  const HeartAppBarStatus({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_rounded, color: kRed),
        const SizedBox(width: 5),
        Text('${appState.hearts}', style: const TextStyle(fontWeight: FontWeight.w900)),
        if (appState.hearts < AppState.maxHearts) ...[
          const SizedBox(width: 8),
          HeartCountdownText(appState: appState, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }
}

class StatsStrip extends StatelessWidget {
  final AppState appState;
  const StatsStrip({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: MiniStat(icon: Icons.local_fire_department_rounded, value: '${appState.streak}', label: 'Chuỗi ngày', color: kOrange)),
        const SizedBox(width: 8),
        Expanded(child: MiniStat(icon: Icons.diamond_rounded, value: '${appState.gems}', label: 'Đá quý', color: kBlue)),
        const SizedBox(width: 8),
        Expanded(child: HeartMiniStat(appState: appState)),
      ],
    );
  }
}

class DailyGoalCard extends StatelessWidget {
  final int xp;
  final int level;
  const DailyGoalCard({super.key, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF28664F), Color(0xFF184B39)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CẤP ĐỘ $level', style: const TextStyle(color: Color(0xFFCBE7D3), fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              const Text('Mục tiêu hôm nay', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: xp / 100, minHeight: 7, backgroundColor: Colors.white24, color: const Color(0xFFFFD27A)),
              ),
              const SizedBox(height: 5),
              Text('$xp/100 XP để lên cấp', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const TipCard({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6EBE4))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFFF1D7), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: kOrange)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(body, style: const TextStyle(color: Colors.black54, height: 1.45))])),
      ]),
    );
  }
}


class LanguageFlagBadge extends StatelessWidget {
  final String flag;
  final double width;
  final double height;

  const LanguageFlagBadge({super.key, required this.flag, this.width = 44, this.height = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E7E0)),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 22)),
    );
  }
}
