import 'package:flutter/material.dart';

import '../core/database/database_service.dart';
import '../core/theme/app_colors.dart';
import '../data/han_character.dart';
import '../data/han_seed_data.dart';
import '../services/ad_service.dart';
import '../state/app_state.dart';
import '../widgets/stats_widgets.dart';
import '../widgets/type_badge.dart';
import 'flashcard_screen.dart';
import 'lesson_screen.dart';
import 'review_screen.dart';
import 'speed_challenge_screen.dart';

class HanTrackScreen extends StatelessWidget {
  final AppState appState;
  final DatabaseService databaseService;
  const HanTrackScreen({super.key, required this.appState, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Row(children: [
            Icon(Icons.eco_rounded, color: kGreen, size: 27),
            SizedBox(width: 8),
            Text('Lộ trình Hán Tự', style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
          actions: [
            IconButton(
              tooltip: 'Xem quảng cáo nạp tim miễn phí',
              onPressed: appState.hearts < 5
                  ? () => AdService.instance.showRewardedAd(
                        context,
                        rewardDescription: '1 Tim ❤️',
                        onRewardGranted: () => appState.addHeart(1),
                      )
                  : null,
              icon: const Icon(Icons.ondemand_video_rounded, color: kOrange),
            ),
            IconButton(
              tooltip: 'Ôn tập tự do',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ReviewScreen(appState: appState, databaseService: databaseService),
              )),
              icon: const Icon(Icons.refresh_rounded, color: kGreen),
            ),
            IconButton(
              tooltip: 'Khôi phục tim (50 đá quý)',
              onPressed: appState.hearts < 5 && appState.gems >= 50
                  ? () async {
                      await appState.restoreHeart();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã đổi 50 đá quý lấy 1 tim.'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  : null,
              icon: const Icon(Icons.favorite_rounded, color: kRed),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              StatsStrip(appState: appState),
              const SizedBox(height: 15),
              DailyGoalCard(xp: appState.xpInLevel, level: appState.level),
              const SizedBox(height: 14),

              // Banner nhận thưởng nạp tim qua AdMob khi tim < 5
              if (appState.hearts < 5) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD4B0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: kRed, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang còn ${appState.hearts}/5 tim',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD35400), fontSize: 13),
                            ),
                            const Text(
                              'Xem video ngắn 10s nhận ngay +1 tim miễn phí!',
                              style: TextStyle(fontSize: 11.5, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        onPressed: () => AdService.instance.showRewardedAd(
                          context,
                          rewardDescription: '1 Tim ❤️',
                          onRewardGranted: () => appState.addHeart(1),
                        ),
                        icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                        label: const Text('Nhận tim'),
                      ),
                    ],
                  ),
                ),
              ],

              // Hai chế độ luyện tập mới: 3D Flashcard & Thử thách 60s
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => FlashcardScreen(appState: appState, databaseService: databaseService),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF28664F), Color(0xFF3B8A6E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x2228664F), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.style_rounded, color: Colors.white, size: 24),
                                Text('3D ANKI', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Lật thẻ Flashcard',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ôn nhớ nhanh 3 mức',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => SpeedChallengeScreen(appState: appState),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCC6B3D), Color(0xFFE28254)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x22CC6B3D), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                                if (appState.speedChallengeHighScore > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Top ${appState.speedChallengeHighScore}',
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Thử thách 60 Giây',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Phản xạ combo x5 điểm',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(18)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.route_rounded, color: kGreen, size: 27),
                  SizedBox(width: 11),
                  Expanded(child: Text('Mỗi bài Hán học 10 chữ cùng chủ đề. Sau mỗi 5 bài có một Tổng Ôn tập lấy ngẫu nhiên 20 chữ trong 50 chữ vừa học.', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, height: 1.4))),
                ]),
              ),
              const SizedBox(height: 22),
              Row(children: [
                const Expanded(child: Text('CÂY KỸ NĂNG HÁN TỰ', style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: kGreen))),
                Text('${appState.hanLessonsCompleted}/$hanCoreLessonCount bài', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              for (var index = 0; index < hanLessonUnits.length; index++) ...[
                if (index % hanLessonsPerCycle == 0) ...[
                  if (index > 0) const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 9),
                    child: Text('CHƯƠNG ${(index ~/ hanLessonsPerCycle) + 1} · HÁN TỰ CỐT LÕI', style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen, fontSize: 11, letterSpacing: 1.0)),
                  ),
                ],
                LessonUnitTile(
                  unit: hanLessonUnits[index],
                  index: index,
                  isUnlocked: appState.isHanLessonUnlocked(index + 1),
                  isCompleted: index + 1 <= appState.hanLessonsCompleted,
                  isCurrent: appState.isHanLessonUnlocked(index + 1) && index + 1 == appState.hanLessonsCompleted + 1,
                  currentPart: appState.currentLessonPart,
                  onTap: () {
                    final lessonNumber = index + 1;
                    if (appState.isHanLessonUnlocked(lessonNumber)) {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => LessonScreen(appState: appState, trackType: 'Hán', trackLessonNumber: lessonNumber),
                      ));
                    } else {
                      _showJumpAheadDialog(context, appState, targetLessonNumber: lessonNumber);
                    }
                  },
                ),
                if ((index + 1) % hanLessonsPerCycle == 0) ...[
                  roadmapConnector(),
                  _ReviewCheckpointTile(
                    checkpointNumber: (index + 1) ~/ hanLessonsPerCycle,
                    isUnlocked: appState.isHanReviewCheckpointUnlocked((index + 1) ~/ hanLessonsPerCycle),
                    isCompleted: appState.isHanReviewCheckpointCompleted((index + 1) ~/ hanLessonsPerCycle),
                    isCurrent: appState.isHanReviewCheckpointUnlocked((index + 1) ~/ hanLessonsPerCycle) && !appState.isHanReviewCheckpointCompleted((index + 1) ~/ hanLessonsPerCycle),
                    onTap: () {
                      final checkpoint = (index + 1) ~/ hanLessonsPerCycle;
                      if (!appState.isHanReviewCheckpointUnlocked(checkpoint)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy hoàn thành đủ 5 bài Hán trước khi làm Tổng Ôn tập.')));
                        return;
                      }
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => LessonScreen(appState: appState, trackType: 'Hán', reviewMode: true, checkpointIndex: checkpoint),
                      ));
                    },
                  ),
                ],
                if (index + 1 < hanLessonUnits.length) roadmapConnector(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget roadmapConnector() => Padding(
  padding: const EdgeInsets.only(left: 36),
  child: Container(width: 3, height: 14, color: const Color(0xFFDDE5DD)),
);

void _showJumpAheadDialog(BuildContext context, AppState appState, {required int targetLessonNumber}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.rocket_launch_rounded, color: kOrange, size: 42),
      title: const Text('Học vượt? 🚀', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
      content: Text(
        'Thử sức với 10 chữ Hán ngẫu nhiên lấy từ các bài đứng trước Bài $targetLessonNumber.\n\n'
        'Bài thi trộn nhận diện chữ, gõ âm Hán-Việt, dịch hai chiều và nhiều câu Hán văn phải tự gõ nghĩa tiếng Việt — không có lựa chọn trắc nghiệm cho phần dịch câu. Hoàn thành để mở khóa Bài Hán $targetLessonNumber và nhận 50 XP.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(width: double.infinity, child: FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Bắt đầu học vượt · 50 XP'),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => LessonScreen(appState: appState, isJumpAhead: true, targetIndex: targetLessonNumber, trackType: 'Hán'),
            ));
          },
        )),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Không, cảm ơn')),
      ],
    ),
  );
}

class LessonUnitTile extends StatelessWidget {
  final LessonUnit unit;
  final int index;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final int currentPart;
  final VoidCallback onTap;
  const LessonUnitTile({
    super.key,
    required this.unit,
    required this.index,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    this.currentPart = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? kGreen : isCurrent ? kOrange : Colors.grey;
    return Material(
      color: isCurrent ? const Color(0xFFF0F6EF) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: isCurrent ? const Color(0xFFB4D5BB) : const Color(0xFFE8ECE7), width: isCurrent ? 1.5 : 1)),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isCompleted || isCurrent)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: isCompleted ? 1.0 : ((currentPart - 1) / 3).clamp(0.0, 1.0).toDouble(),
                          strokeWidth: 3.5,
                          backgroundColor: const Color(0xFFE4E9E3),
                          valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? kGreen : kOrange),
                        ),
                      ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: isUnlocked ? color.withOpacity(0.12) : const Color(0xFFF0F1EF), borderRadius: BorderRadius.circular(15)),
                      alignment: Alignment.center,
                      child: isCompleted
                          ? const Icon(Icons.check_circle_rounded, color: kGreen, size: 27)
                          : isUnlocked
                              ? Text(unit.icon, style: const TextStyle(fontSize: 23))
                              : const Icon(Icons.lock_outline_rounded, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BÀI ${index + 1}', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 3),
                  Text(unit.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 5),
                  Align(alignment: Alignment.centerLeft, child: TypeBadge(type: unit.type, compact: true)),
                  const SizedBox(height: 3),
                  Text(unit.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (isCurrent || isCompleted) ...[
                    const SizedBox(height: 5),
                    Text(
                      isCompleted ? 'Đã hoàn thành · 3/3 phần' : 'ĐANG HỌC · PHẦN $currentPart/3',
                      style: TextStyle(fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w900, color: isCompleted ? kGreen : kOrange),
                    ),
                  ],
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: isCompleted ? 1.0 : isCurrent ? ((currentPart - 1) / 3).clamp(0.0, 1.0).toDouble() : 0.0, minHeight: 5, backgroundColor: const Color(0xFFE9EDE8), color: color),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(isCompleted ? Icons.check_rounded : isUnlocked ? Icons.chevron_right_rounded : Icons.lock_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCheckpointTile extends StatelessWidget {
  final int checkpointNumber;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ReviewCheckpointTile({
    required this.checkpointNumber,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isUnlocked ? const Color(0xFFB98216) : Colors.grey;
    return Material(
      color: isCurrent ? const Color(0xFFFFF6E2) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCurrent ? const Color(0xFFE8C66C) : const Color(0xFFE8ECE7), width: isCurrent ? 1.7 : 1),
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: isUnlocked ? const Color(0xFFFFE9AA) : const Color(0xFFF0F1EF), borderRadius: BorderRadius.circular(17)),
              child: Icon(isCompleted ? Icons.verified_rounded : isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                  color: isCompleted ? kGreen : accent, size: 30),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MỐC ${checkpointNumber * 5} · ÔN TẬP ${checkpointNumber}', style: TextStyle(fontSize: 12, letterSpacing: 1.0, color: accent, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Tổng Ôn tập', style: TextStyle(fontSize: 16, color: isUnlocked ? const Color(0xFF20372C) : Colors.black38, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('20 chữ ngẫu nhiên trong 50 chữ của Bài ${(checkpointNumber - 1) * hanLessonsPerCycle + 1}–${checkpointNumber * hanLessonsPerCycle}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ])),
            if (isCompleted) const Icon(Icons.check_circle_rounded, color: kGreen),
          ]),
        ),
      ),
    );
  }
}
