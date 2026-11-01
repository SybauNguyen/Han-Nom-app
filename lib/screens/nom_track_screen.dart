import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/han_seed_data.dart';
import '../state/app_state.dart';
import '../widgets/stats_widgets.dart';
import '../widgets/type_badge.dart';
import 'han_track_screen.dart';
import 'lesson_screen.dart';

class NomTrackScreen extends StatelessWidget {
  final AppState appState;
  const NomTrackScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    if (!isNomDataEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: kOrange, size: 26),
            SizedBox(width: 8),
            Text('Chữ Nôm', style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: kNomLight, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFF0D5C3))),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.fact_check_outlined, color: kOrange, size: 48),
                SizedBox(height: 14),
                Text('Dữ liệu Chữ Nôm đang tạm ẩn', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kOrange)),
                SizedBox(height: 9),
                Text('Các mục chữ Nôm cũ đã được gỡ để tránh sai lệch chuẩn hóa. Màn học, mô hình câu hỏi, lộ trình khung và chức năng từ điển vẫn được giữ lại để tích hợp bộ dữ liệu chuẩn sau này.', textAlign: TextAlign.center, style: TextStyle(height: 1.45, color: Color(0xFF70442F))),
              ]),
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: kOrange, size: 26),
            SizedBox(width: 8),
            Text('Lộ trình Chữ Nôm', style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              StatsStrip(appState: appState),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(color: kNomLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0D5C3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.lock_open_rounded, color: kOrange, size: 24), SizedBox(width: 9), Expanded(child: Text('Học Nôm bằng nền tảng Hán tự', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kOrange)))]),
                  const SizedBox(height: 8),
                  Text('Dữ liệu Nôm đang tạm ẩn để chuẩn hóa. Màn học và bộ lọc từ điển sẽ được giữ lại khi bộ chữ chuẩn sẵn sàng.', style: const TextStyle(height: 1.4, color: Color(0xFF70442F))),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: appState.unlockedNomLessons / nomTrackLessonCount, minHeight: 7, backgroundColor: Colors.white, color: kOrange)),
                ]),
              ),
              const SizedBox(height: 22),
              Row(children: [
                const Expanded(child: Text('CÂY KỸ NĂNG CHỮ NÔM', style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: kOrange))),
                Text('${appState.nomLessonsCompleted}/${nomTrackLessonCount} bài', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              for (var index = 0; index < nomLessonUnits.length; index++) ...[
                LessonUnitTile(
                  unit: nomLessonUnits[index],
                  index: index,
                  isUnlocked: appState.isNomLessonUnlocked(index + 1),
                  isCompleted: index + 1 <= appState.nomLessonsCompleted,
                  isCurrent: appState.isNomLessonUnlocked(index + 1) && index + 1 == appState.nomLessonsCompleted + 1,
                  onTap: () {
                    final lessonNumber = index + 1;
                    if (!appState.isNomLessonUnlocked(lessonNumber)) {
                      final neededCheckpoint = lessonNumber;
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          icon: const TypeBadge(type: 'Nôm'),
                          title: const Text('Bài Nôm đang khóa'),
                          content: Text('Hãy hoàn thành 5 bài Hán và vượt qua Tổng Ôn tập số $neededCheckpoint để mở khóa bài Nôm này. Hiện bạn đã vượt ${appState.completedHanReviewCheckpoints} mốc.'),
                          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Đã hiểu'))],
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => LessonScreen(appState: appState, trackType: 'Nôm', trackLessonNumber: lessonNumber),
                    ));
                  },
                ),
                if (index + 1 < nomLessonUnits.length) roadmapConnector(),
              ],
              const SizedBox(height: 18),
              const TipCard(icon: Icons.extension_rounded, title: 'Lắp chữ từ thành phần quen thuộc', body: 'Mẹo nhớ Nôm trong app là gợi ý sư phạm. Hãy đối chiếu với tài liệu Hán-Nôm chuyên môn trước khi xem phần phân tích là kết luận học thuật.'),
            ],
          ),
        ),
      ),
    );
  }
}
