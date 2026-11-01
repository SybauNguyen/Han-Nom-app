import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/han_seed_data.dart';
import '../state/app_state.dart';
import '../widgets/stats_widgets.dart';

class ProfileScreen extends StatelessWidget {
  final AppState appState;
  const ProfileScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final masteredCount = appState.mastery.values.where((value) => value >= 3).length;
        final studiedHanCount = appState.mastery.entries
            .where((entry) => entry.value > 0 && findCharacter(entry.key)?.isHan == true)
            .length;
        final decodedNomCount = appState.mastery.entries
            .where((entry) => entry.value > 0 && findCharacter(entry.key)?.isNom == true)
            .length;
        return Scaffold(
          appBar: AppBar(title: const Text('Hồ sơ học tập', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  Container(width: 84, height: 84, decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.person_rounded, color: kGreen, size: 48)),
                  const SizedBox(height: 12),
                  const Text('Học giả Hán-Việt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                  const SizedBox(height: 5),
                  Text('Cấp độ ${appState.level} • ${appState.xp} XP tích lũy', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _ProfileMetric(value: '${appState.completedLessons}', label: 'Bài hoàn thành', icon: Icons.flag_rounded)),
                    Expanded(child: _ProfileMetric(value: '${appState.streak}', label: 'Chuỗi ngày', icon: Icons.local_fire_department_rounded)),
                    Expanded(child: _ProfileMetric(value: '$masteredCount', label: 'Chữ nhớ tốt', icon: Icons.school_rounded)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('TIẾN ĐỘ GIẢI MÃ', style: TextStyle(fontSize: 12, letterSpacing: 1.1, color: kGreen, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 13),
                    Row(children: [
                      Expanded(child: _ProfileMetric(value: '$studiedHanCount/250', label: 'Hán tự đã học', icon: Icons.menu_book_rounded)),
                      Container(width: 1, height: 52, color: const Color(0xFFE4E9E3)),
                      Expanded(child: _ProfileMetric(value: isNomDataEnabled ? '$decodedNomCount/$nomCharacterCount' : 'Tạm ẩn', label: 'Chữ Nôm giải mã', icon: Icons.translate_rounded)),
                    ]),
                    if (appState.unlockedNomLessons < nomTrackLessonCount) ...[
                      const SizedBox(height: 10),
                      Text('Đã mở ${appState.unlockedNomLessons}/$nomTrackLessonCount bài Nôm. Ba mốc Tổng Ôn tập đầu tiên mở khóa từng bài theo thứ tự.', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              _LastStudyCard(lastActivity: appState.lastActivity, streak: appState.streak),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('NGÔN NGỮ ĐỌC BỔ SUNG', style: TextStyle(fontSize: 12, letterSpacing: 1.1, color: kGreen, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    const Text('Hán-Việt vẫn là phần chính. Chọn một hệ thống để hiện thêm trong thẻ chi tiết và khi chạm chữ ở bài học; không hiển thị tất cả cùng lúc.', style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black54)),
                    const SizedBox(height: 8),
                    for (final language in const [
                      SupplementaryLanguage.none,
                      SupplementaryLanguage.mandarin,
                      SupplementaryLanguage.japanese,
                    ])
                      RadioListTile<SupplementaryLanguage>(
                        value: language,
                        groupValue: appState.supplementaryLanguage,
                        onChanged: (value) {
                          if (value != null) appState.setSupplementaryLanguage(value);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        secondary: LanguageFlagBadge(flag: language.flagEmoji),
                        title: Text(language.choiceLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        subtitle: Text(language.choiceDescription),
                        activeColor: kGreen,
                      ),
                    const Divider(height: 1),
                    for (final language in const [SupplementaryLanguage.hanja, SupplementaryLanguage.cantonese])
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: LanguageFlagBadge(flag: language.flagEmoji, width: 40, height: 30),
                        title: Text(language.choiceLabel, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w700)),
                        subtitle: const Text('Dự kiến bổ sung ở giai đoạn sau', style: TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.lock_outline_rounded, color: Colors.black38, size: 18),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              const Text('THÀNH TỰU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12, color: kGreen)),
              const SizedBox(height: 10),
              _AchievementTile(title: 'Bước đầu tiên', description: 'Hoàn thành bài học đầu tiên', icon: Icons.flag_rounded, unlocked: appState.completedLessons >= 1),
              const SizedBox(height: 8),
              _AchievementTile(title: 'Người học chăm chỉ', description: 'Hoàn thành 3 bài học', icon: Icons.local_fire_department_rounded, unlocked: appState.completedLessons >= 3),
              const SizedBox(height: 8),
              _AchievementTile(title: 'Tích lũy kiến thức', description: 'Đạt 100 XP', icon: Icons.bolt_rounded, unlocked: appState.xp >= 100),
              const SizedBox(height: 8),
              _AchievementTile(title: 'Học giả', description: 'Thuần thục ít nhất 5 chữ', icon: Icons.workspace_premium_rounded, unlocked: masteredCount >= 5),
              const SizedBox(height: 20),
              const TipCard(icon: Icons.cloud_done_outlined, title: 'Tiến độ được lưu trên thiết bị', body: 'XP, đá quý, tim, bài đã mở khóa và mức độ ghi nhớ được lưu cục bộ trên máy này.'),
            ],
          ),
        );
      },
    );
  }
}

class _LastStudyCard extends StatelessWidget {
  final DateTime? lastActivity;
  final int streak;
  const _LastStudyCard({required this.lastActivity, required this.streak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final activity = lastActivity?.toLocal();
    final dayDifference = activity == null
        ? null
        : DateTime.utc(now.year, now.month, now.day)
            .difference(DateTime.utc(activity.year, activity.month, activity.day))
            .inDays;

    final String status;
    final IconData icon;
    final Color color;
    if (activity == null) {
      status = 'Hoàn thành bài đầu tiên để bắt đầu chuỗi học.';
      icon = Icons.flag_outlined;
      color = kBlue;
    } else if (dayDifference == 0) {
      status = 'Bạn đã học hôm nay. Chuỗi hiện tại đã được ghi nhận.';
      icon = Icons.check_circle_rounded;
      color = kGreen;
    } else if (dayDifference == 1) {
      status = 'Học một bài hôm nay để tiếp tục chuỗi $streak ngày.';
      icon = Icons.local_fire_department_rounded;
      color = kOrange;
    } else if (dayDifference != null && dayDifference > 1) {
      status = 'Chuỗi cũ đã gián đoạn. Hoàn thành bài hôm nay để bắt đầu lại từ 1.';
      icon = Icons.refresh_rounded;
      color = kRed;
    } else {
      status = 'Ngày học gần nhất: ${_formatDate(activity)}.';
      icon = Icons.history_rounded;
      color = kBlue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6EBE4))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHUỖI NGÀY HỌC', style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: Colors.black54, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(status, style: const TextStyle(height: 1.4, fontWeight: FontWeight.w700)),
                if (activity != null) ...[
                  const SizedBox(height: 5),
                  Text('Lần học gần nhất: ${_formatDate(activity)}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _ProfileMetric({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Icon(icon, color: kGreen, size: 22), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54))]);
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  const _AchievementTile({required this.title, required this.description, required this.icon, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(leading: CircleAvatar(backgroundColor: unlocked ? const Color(0xFFFFE9B5) : const Color(0xFFEDEEEB), child: Icon(icon, color: unlocked ? kOrange : Colors.black38)), title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: unlocked ? const Color(0xFF20372C) : Colors.black54)), subtitle: Text(description), trailing: Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded, color: unlocked ? kGreen : Colors.black26)));
  }
}
