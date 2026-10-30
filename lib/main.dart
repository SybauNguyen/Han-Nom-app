import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'data/han_character.dart';
import 'data/models/cjk_character.dart';
import 'data/dictionary_search.dart';
import 'data/han_seed_data.dart';
import 'core/database/database_service.dart';
import 'data/question.dart';
import 'state/app_state.dart';
import 'widgets/fill_in_the_blank_widget.dart';
import 'widgets/introduce_word_widget.dart';
import 'widgets/matching_pairs_widget.dart';
import 'widgets/translate_sentence_widget.dart';
import 'widgets/type_badge.dart';

const Color kGreen = Color(0xFF28664F);
const Color kGreenLight = Color(0xFFE4F1E8);
const Color kPaper = Color(0xFFF7F8F3);
const Color kOrange = Color(0xFFCC6B3D);
const Color kNomLight = Color(0xFFFFEBDD);
const Color kBlue = Color(0xFF3186C8);
const Color kRed = Color(0xFFD94343);

bool _hasProvisionalImportedMeaning(HanCharacter character) =>
    !character.inCurriculum && character.isNom &&
    character.meaning.trim().toLowerCase() == character.hanVietReading.trim().toLowerCase();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HanVietApp());
}

class HanVietApp extends StatefulWidget {
  const HanVietApp({super.key});

  @override
  State<HanVietApp> createState() => _HanVietAppState();
}

class _HanVietAppState extends State<HanVietApp> with WidgetsBindingObserver {
  late final AppState _appState;
  late final DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState = AppState();
    _appState.load();
    _databaseService = DatabaseService();
    _databaseService.initialize().then((_) async {
      final cjkRecords = await _databaseService.getCjkCharacters(limit: 1000);
      _appState.setCjkCharacters(cjkRecords);
    }).catchError((Object error) {
      debugPrint('Dictionary database initialization failed: $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appState.refreshHeartRegeneration();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hán-Việt Duo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
        // Giữ font hệ thống làm font chính cho tiếng Việt Quốc ngữ;
        // NomNaTong chỉ là font fallback cho glyph Hán-Nôm còn thiếu.
        textTheme: ThemeData.light().textTheme.apply(
          fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
        ),
        primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
          fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
        ),
        scaffoldBackgroundColor: kPaper,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPaper,
          foregroundColor: Color(0xFF20372C),
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE4E9E3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kGreen, width: 1.5),
          ),
        ),
      ),
      home: AppShell(appState: _appState, databaseService: _databaseService),
    );
  }
}

class AppShell extends StatefulWidget {
  final AppState appState;
  final DatabaseService databaseService;
  const AppShell({super.key, required this.appState, required this.databaseService});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _languagePromptQueued = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_maybeShowSupplementaryLanguagePrompt);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowSupplementaryLanguagePrompt());
  }

  void _maybeShowSupplementaryLanguagePrompt() {
    if (!mounted ||
        !widget.appState.isReady ||
        widget.appState.hasSeenSupplementaryLanguagePrompt ||
        _languagePromptQueued) {
      return;
    }
    _languagePromptQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.appState.hasSeenSupplementaryLanguagePrompt) return;
      unawaited(showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SupplementaryLanguageWelcomeDialog(appState: widget.appState),
      ));
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_maybeShowSupplementaryLanguagePrompt);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HanTrackScreen(appState: widget.appState, databaseService: widget.databaseService),
      NomTrackScreen(appState: widget.appState),
      DictionaryScreen(appState: widget.appState, databaseService: widget.databaseService),
      ProfileScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: kGreenLight,
        destinations: const [
          NavigationDestination(
            icon: Text('漢', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF87958D), fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
            selectedIcon: Text('漢', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kGreen, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
            label: 'Hán Tự',
          ),
          NavigationDestination(
            icon: Text('喃', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFB9A095), fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
            selectedIcon: Text('喃', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kOrange, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
            label: 'Chữ Nôm',
          ),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Từ điển'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

class _LanguageFlagBadge extends StatelessWidget {
  final String flag;
  final double width;
  final double height;

  const _LanguageFlagBadge({required this.flag, this.width = 44, this.height = 34});

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

class _SupplementaryLanguageWelcomeDialog extends StatelessWidget {
  final AppState appState;
  const _SupplementaryLanguageWelcomeDialog({required this.appState});

  void _choose(BuildContext context, SupplementaryLanguage language) {
    unawaited(appState.finishSupplementaryLanguagePrompt(selection: language));
    Navigator.of(context).pop();
  }

  void _skip(BuildContext context) {
    unawaited(appState.finishSupplementaryLanguagePrompt());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🇻🇳  Hán-Việt Duo', style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.w900)),
        SizedBox(height: 9),
        Text('Bạn muốn hiển thị thêm ngôn ngữ nào?', style: TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.w900)),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Hán-Việt luôn được giữ làm lớp đọc chính. Bạn có thể chọn một hệ thống bổ sung hoặc bỏ qua và đổi lại trong Hồ sơ bất cứ lúc nào.',
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.black54),
            ),
          ),
          _WelcomeLanguageOption(
            language: SupplementaryLanguage.none,
            onTap: () => _choose(context, SupplementaryLanguage.none),
          ),
          const SizedBox(height: 8),
          _WelcomeLanguageOption(
            language: SupplementaryLanguage.mandarin,
            onTap: () => _choose(context, SupplementaryLanguage.mandarin),
          ),
          const SizedBox(height: 8),
          _WelcomeLanguageOption(
            language: SupplementaryLanguage.japanese,
            onTap: () => _choose(context, SupplementaryLanguage.japanese),
          ),
          const SizedBox(height: 8),
          _WelcomeLanguageOption(language: SupplementaryLanguage.hanja, enabled: false),
          const SizedBox(height: 8),
          _WelcomeLanguageOption(language: SupplementaryLanguage.cantonese, enabled: false),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => _skip(context),
          child: const Text('Bỏ qua', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _WelcomeLanguageOption extends StatelessWidget {
  final SupplementaryLanguage language;
  final bool enabled;
  final VoidCallback? onTap;

  const _WelcomeLanguageOption({required this.language, this.enabled = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: enabled ? Colors.white : const Color(0xFFF5F6F3),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFDDE5DB)),
            ),
            child: Row(children: [
              _LanguageFlagBadge(flag: language.flagEmoji, width: 48, height: 40),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(language.choiceLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF263A2F))),
                const SizedBox(height: 3),
                Text(language.choiceDescription, style: const TextStyle(fontSize: 11, height: 1.3, color: Colors.black54)),
              ])),
              if (enabled)
                const Icon(Icons.chevron_right_rounded, color: kGreen)
              else
                const Text('Sắp có', style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }
}

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
              _StatsStrip(appState: appState),
              const SizedBox(height: 15),
              _DailyGoalCard(xp: appState.xpInLevel, level: appState.level),
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
                _LessonUnitTile(
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
                  _roadmapConnector(),
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
                if (index + 1 < hanLessonUnits.length) _roadmapConnector(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
              _StatsStrip(appState: appState),
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
                _LessonUnitTile(
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
                if (index + 1 < nomLessonUnits.length) _roadmapConnector(),
              ],
              const SizedBox(height: 18),
              const _TipCard(icon: Icons.extension_rounded, title: 'Lắp chữ từ thành phần quen thuộc', body: 'Mẹo nhớ Nôm trong app là gợi ý sư phạm. Hãy đối chiếu với tài liệu Hán-Nôm chuyên môn trước khi xem phần phân tích là kết luận học thuật.'),
            ],
          ),
        ),
      ),
    );
  }
}

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

Widget _roadmapConnector() => Padding(
  padding: const EdgeInsets.only(left: 36),
  child: Container(width: 3, height: 14, color: const Color(0xFFDDE5DD)),
);

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

class _StatsStrip extends StatelessWidget {
  final AppState appState;
  const _StatsStrip({required this.appState});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(icon: Icons.local_fire_department_rounded, value: '${appState.streak}', label: 'Chuỗi ngày', color: kOrange)),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat(icon: Icons.diamond_rounded, value: '${appState.gems}', label: 'Đá quý', color: kBlue)),
        const SizedBox(width: 8),
        Expanded(child: _HeartMiniStat(appState: appState)),
      ],
    );
  }
}

class _HeartMiniStat extends StatelessWidget {
  final AppState appState;
  const _HeartMiniStat({required this.appState});

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
              Flexible(child: _HeartCountdownText(appState: appState, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w800))),
            ],
          ]),
        ],
      ),
    );
  }
}

class _HeartCountdownText extends StatefulWidget {
  final AppState appState;
  final TextStyle? style;
  const _HeartCountdownText({required this.appState, this.style});

  @override
  State<_HeartCountdownText> createState() => _HeartCountdownTextState();
}

class _HeartCountdownTextState extends State<_HeartCountdownText> {
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
    if (widget.appState.hearts >= AppState.maxHearts || widget.appState.lastHeartRegenTime == null) {
      return const SizedBox.shrink();
    }
    return Text(_formatCountdown(), style: widget.style, semanticsLabel: 'Thời gian hồi tim còn lại ${_formatCountdown()}');
  }
}

class _HeartAppBarStatus extends StatelessWidget {
  final AppState appState;
  const _HeartAppBarStatus({required this.appState});

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
          _HeartCountdownText(appState: appState, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE9EDE8))),
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

class _DailyGoalCard extends StatelessWidget {
  final int xp;
  final int level;
  const _DailyGoalCard({required this.xp, required this.level});

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

class _LessonUnitTile extends StatelessWidget {
  final LessonUnit unit;
  final int index;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final int currentPart;
  final VoidCallback onTap;
  const _LessonUnitTile({required this.unit, required this.index, required this.isUnlocked, required this.isCompleted, required this.isCurrent, this.currentPart = 1, required this.onTap});

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

bool _nomCharacterIsUnlocked(HanCharacter character, AppState appState) {
  if (!character.isNom || appState.unlockedNomLessons <= 0) return false;
  final unlockedSymbols = nomLessonUnits
      .take(appState.unlockedNomLessons)
      .expand((unit) => unit.characters)
      .toSet();
  return unlockedSymbols.contains(character.character);
}

class ReviewScreen extends StatelessWidget {
  final AppState appState;
  final DatabaseService? databaseService;
  const ReviewScreen({super.key, required this.appState, this.databaseService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final reviewCharacters = seedCharacters
            .where((character) => character.isHan || _nomCharacterIsUnlocked(character, appState))
            .toList()
          ..sort((a, b) => appState.masteryOf(a.character).compareTo(appState.masteryOf(b.character)));
        final due = reviewCharacters.take(8).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Ôn tập mỗi ngày', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(22)),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.psychology_alt_rounded, color: kGreen, size: 32),
                  SizedBox(height: 10),
                  Text('Nhớ lâu hơn bằng cách ôn lại', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF20372C))),
                  SizedBox(height: 6),
                  Text('Các chữ có mức thuần thục thấp được ưu tiên lên đầu danh sách.', style: TextStyle(height: 1.4, color: Colors.black54)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [const Expanded(child: Text('GỢI Ý ÔN TẬP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: kGreen, fontSize: 12))), Text('${due.length} chữ', style: const TextStyle(color: Colors.black54))]),
              const SizedBox(height: 10),
              for (final character in due)
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CharacterDetailScreen(character: character, appState: appState, databaseService: databaseService))),
                    leading: Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: character.isNom ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(14)), child: Text(character.character, style: const TextStyle(fontFamilyFallback: ['NomNaTong', 'HanNomB']).copyWith(fontSize: 27, color: character.isNom ? kOrange : kGreen, fontWeight: FontWeight.w600))),
                    title: Row(children: [Expanded(child: Text(character.isNom ? 'Cách đọc: ${character.hanVietReading}' : character.hanVietReading.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))), TypeBadge(type: character.type, compact: true)]),
                    subtitle: Text(_hasProvisionalImportedMeaning(character) ? 'Nghĩa chưa được biên tập  •  Thuần thục ${appState.masteryOf(character.character)}/5' : '${character.meaning}  •  Thuần thục ${appState.masteryOf(character.character)}/5'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(appState: appState, reviewMode: true))),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Bắt đầu ôn tập'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  final AppState appState;
  final DatabaseService databaseService;
  const DictionaryScreen({super.key, required this.appState, required this.databaseService});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _typeFilter = 'Tất cả';
  List<HanCharacter> _results = [];
  bool _isSearching = true;
  int _matchCount = 0;
  int _requestGeneration = 0;
  static const int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadResults(reset: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value);
    _loadResults(reset: true);
  }

  Future<void> _loadResults({required bool reset}) async {
    final request = ++_requestGeneration;
    final query = _query;
    final type = _typeFilter;
    final offset = reset ? 0 : _results.length;
    if (reset && mounted) setState(() => _isSearching = true);
    try {
      final count = await widget.databaseService.countDictionary(
        type: type == 'Tất cả' ? null : type,
        query: query,
      );
      final page = await widget.databaseService.searchDictionary(
        query,
        type: type,
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted || request != _requestGeneration) return;
      setState(() {
        _matchCount = count;
        if (reset) {
          _results = page;
        } else {
          _results = [..._results, ...page];
        }
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted || request != _requestGeneration) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được từ điển: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ điển Hán-Việt', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(20)),
                child: Text('$_matchCount mục', style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (widget.databaseService.lastImportError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A5A20)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Chưa nạp được dictionary.json. Từ điển có thể chỉ hiện dữ liệu lõi. Hãy kiểm tra assets/data/dictionary.json rồi chạy refresh_web_build.bat. Chi tiết: ${widget.databaseService.lastImportError}',
                        style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF70442F)),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tra chữ, nhớ nghĩa, hiểu bộ thủ.', style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    onChanged: (value) {
                      setState(() => _query = value);
                      _loadResults(reset: true);
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Nhập Hán tự, âm đọc hoặc nghĩa...',
                      prefixIcon: const Icon(Icons.search_rounded, color: kGreen),
                      suffixIcon: _query.isEmpty ? null : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () => _setQuery(''),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 7, children: [
                    for (final type in ['Tất cả', 'Hán', 'Nôm'])
                      ChoiceChip(
                        label: Text(type == 'Hán' ? 'Hán tự' : type == 'Nôm' ? (isNomDataEnabled ? 'Chữ Nôm' : 'Nôm · tạm ẩn') : 'Tất cả'),
                        selected: _typeFilter == type,
                        selectedColor: type == 'Nôm' ? kNomLight : kGreenLight,
                        onSelected: (_) {
                          setState(() => _typeFilter = type);
                          _loadResults(reset: true);
                        },
                      ),
                  ]),
                  const SizedBox(height: 9),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final popular in ['nhất', 'trung', 'học', 'tâm', 'người', 'nghia', 'trời', 'đi']) ...[
                        ActionChip(
                          label: Text(popular),
                          onPressed: () => _setQuery(popular),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE4E9E3)),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 9),
              child: Row(children: [
                Expanded(child: Text(
                  _query.trim().isEmpty ? (isNomDataEnabled ? 'KHÁM PHÁ HÁN TỰ & CHỮ NÔM' : 'KHÁM PHÁ HÁN TỰ · NÔM ĐANG CHUẨN HÓA') : 'KẾT QUẢ TRA CỨU',
                  style: const TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: kGreen),
                )),
                Text('${_results.length}/$_matchCount', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: _isSearching && _results.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? _DictionaryEmptyState(query: _query, typeFilter: _typeFilter)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _results.length + (_results.length < _matchCount ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            if (index >= _results.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: OutlinedButton.icon(
                                  onPressed: _isSearching ? null : () => _loadResults(reset: false),
                                  icon: _isSearching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.expand_more_rounded),
                                  label: Text('Tải thêm mục từ (${_results.length}/$_matchCount)'),
                                ),
                              );
                            }
                            final character = _results[index];
                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => CharacterDetailScreen(character: character, appState: widget.appState, databaseService: widget.databaseService),
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                                  child: Row(children: [
                                    Container(
                                      width: 60,
                                      height: 64,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: character.isNom ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(15)),
                                      child: Text(character.character, style: const TextStyle(fontFamilyFallback: ['NomNaTong', 'HanNomB']).copyWith(fontSize: 34, height: 1.1, color: character.isNom ? kOrange : kGreen, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [Expanded(child: Text(character.isNom ? 'Cách đọc: ${character.hanVietReading}' : character.hanVietReading.toUpperCase(), style: const TextStyle(fontSize: 15, letterSpacing: 0.2, fontWeight: FontWeight.w900, color: Color(0xFF20372C)))), const SizedBox(width: 5), TypeBadge(type: character.type, compact: true)]),
                                      const SizedBox(height: 4),
                                      Text(character.meaning, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87)),
                                      if (_hasProvisionalImportedMeaning(character)) const Padding(padding: EdgeInsets.only(top: 3), child: Text('Cách đọc từ RIME; chưa có nghĩa biên tập', style: TextStyle(fontSize: 10, color: kOrange, fontWeight: FontWeight.w700))),
                                      if (character.examples.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text('Ví dụ: ${character.examples.first}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                      ],
                                      if (!character.inCurriculum) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Từ điển mở rộng', style: TextStyle(fontSize: 10, color: kBlue, fontWeight: FontWeight.w800))),
                                    ])),
                                    const SizedBox(width: 8),
                                    Column(mainAxisSize: MainAxisSize.min, children: [
                                      const Text('BỘ THỦ', style: TextStyle(fontSize: 9, letterSpacing: 0.6, fontWeight: FontWeight.w900, color: Colors.black45)),
                                      const SizedBox(height: 3),
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(color: const Color(0xFFFFF0E6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF2D6C4))),
                                        child: Text(character.radical.isEmpty ? '—' : character.radical, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: kOrange, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
                                      ),
                                    ]),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 20),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DictionaryEmptyState extends StatelessWidget {
  final String query;
  final String typeFilter;
  const _DictionaryEmptyState({required this.query, required this.typeFilter});

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final nomPaused = typeFilter == 'Nôm' && !isNomDataEnabled;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasQuery ? Icons.search_off_rounded : Icons.menu_book_rounded, size: 62, color: Colors.black26),
            const SizedBox(height: 14),
            Text(nomPaused ? 'Dữ liệu chữ Nôm đang tạm ẩn' : hasQuery ? 'Chưa tìm thấy “$query”' : 'Từ điển đang trống', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(
              nomPaused ? 'Các mục Nôm cũ đã được gỡ để chuẩn hóa lại Unicode và cách đọc. Chức năng tra cứu vẫn được giữ để dùng với bộ dữ liệu chuẩn sau này.' : hasQuery ? 'Thử tìm bằng Hán tự, âm Hán-Việt, nghĩa hoặc bộ thủ. Bạn cũng có thể gõ tiếng Việt không dấu.' : 'Kho dữ liệu hiện hiển thị các mục Hán-Việt đang được hỗ trợ. Dữ liệu Nôm tạm ẩn trong thời gian chuẩn hóa.',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.45, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterDetailScreen extends StatelessWidget {
  final HanCharacter character;
  final AppState appState;
  final DatabaseService? databaseService;
  const CharacterDetailScreen({super.key, required this.character, required this.appState, this.databaseService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character.isNom ? 'Thẻ học chữ Nôm' : 'Thẻ học Hán tự', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(color: character.isNom ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(26)),
            child: Column(children: [
              Text(character.character, style: const TextStyle(fontFamilyFallback: ['NomNaTong', 'HanNomB']).copyWith(fontSize: 104, height: 1.15, fontWeight: FontWeight.w500, color: character.isNom ? kOrange : kGreen)),
              const SizedBox(height: 8),
              TypeBadge(type: character.type),
              const SizedBox(height: 8),
              Text(character.isNom ? 'CÁCH ĐỌC TIẾNG VIỆT' : 'ÂM HÁN-VIỆT', style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 4),
              Text(character.isNom ? character.hanVietReading : character.hanVietReading.toUpperCase(), style: const TextStyle(color: kOrange, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              if (!character.isNom && appState.supplementaryLanguage != SupplementaryLanguage.none) ...[
                const SizedBox(height: 12),
                FutureBuilder<CjkCharacter?>(
                  future: databaseService?.getCjkCharacter(character.character),
                  builder: (context, snapshot) {
                    final language = appState.supplementaryLanguage;
                    final record = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (record == null || !record.hasReadingFor(language)) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.72), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          'Chưa có dữ liệu ${language.label} cho chữ này',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    final displayChar = record.getDisplayChar(language);
                    final readings = record.getReadings(language).join(' · ');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDCE8DD))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(12)),
                            child: Text(displayChar, style: const TextStyle(fontSize: 31, height: 1.0, fontWeight: FontWeight.w700, color: kGreen, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
                          ),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 46, color: const Color(0xFFDCE8DD)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${language.label.toUpperCase()} · ${language.readingLabel.toUpperCase()}', style: const TextStyle(fontSize: 9, letterSpacing: 0.8, color: Colors.black45, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(readings, style: const TextStyle(fontSize: 20, color: kGreen, fontWeight: FontWeight.w900)),
                              Text(language.characterFormLabel, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 7),
              Text(character.meaning, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: Color(0xFF32473B))),
              if (_hasProvisionalImportedMeaning(character)) ...[
                const SizedBox(height: 10),
                const Text('Lưu ý: dữ liệu RIME cung cấp cách gõ/cách đọc, không phải định nghĩa Hán-Nôm đã được biên tập.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.35, color: kOrange)),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          const Text('THÔNG TIN CHỮ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.3, color: kGreen)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF2D6C4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
                  child: Text(character.radical.isEmpty ? '—' : character.radical, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: kOrange, fontFamilyFallback: ['NomNaTong', 'HanNomB'])),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(character.isNom ? 'THÀNH PHẦN GỢI NGHĨA' : 'BỘ THỦ', style: const TextStyle(fontSize: 11, letterSpacing: 1.0, color: kOrange, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(character.isNom ? 'Thành phần Hán tự dùng để gợi nghĩa hoặc tra cứu' : 'Bộ gốc dùng để tra cứu chữ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF653E2B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _InfoCard(label: 'Cấu tạo', value: character.structure, icon: Icons.dashboard_customize_outlined),
          if (character.mnemonic != null && character.mnemonic!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFF7DF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF3DEA0))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFB98216), size: 25),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('MẸO NHỚ', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Color(0xFF9A6D0D))),
                  const SizedBox(height: 5),
                  Text(character.mnemonic!, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF5E4A25))),
                ])),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          _InfoCard(label: 'Độ khó', value: 'Cấp ${character.difficulty}', icon: Icons.stairs_outlined),
          const SizedBox(height: 20),
          const Text('TỪ GHÉP GỢI Ý', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.3, color: kGreen)),
          const SizedBox(height: 8),
          if (character.examples.isEmpty)
            const Text('Chưa có từ ghép cho chữ này.')
          else
            for (final example in character.examples)
              Card(child: ListTile(leading: const Icon(Icons.auto_stories_outlined, color: kGreen), title: Text(example, style: const TextStyle(fontWeight: FontWeight.w700)))),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: appState,
            builder: (context, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [const Icon(Icons.insights_rounded, color: kBlue), const SizedBox(width: 10), Expanded(child: Text('Mức thuần thục: ${appState.masteryOf(character.character)}/5', style: const TextStyle(fontWeight: FontWeight.w800))), const Icon(Icons.auto_awesome, color: kOrange)]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(leading: Icon(icon, color: kGreen), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)), subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF20372C)))));
  }
}

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
                        secondary: _LanguageFlagBadge(flag: language.flagEmoji),
                        title: Text(language.choiceLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        subtitle: Text(language.choiceDescription),
                        activeColor: kGreen,
                      ),
                    const Divider(height: 1),
                    for (final language in const [SupplementaryLanguage.hanja, SupplementaryLanguage.cantonese])
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: _LanguageFlagBadge(flag: language.flagEmoji, width: 40, height: 30),
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
              const _TipCard(icon: Icons.cloud_done_outlined, title: 'Tiến độ được lưu trên thiết bị', body: 'XP, đá quý, tim, bài đã mở khóa và mức độ ghi nhớ được lưu cục bộ trên máy này.'),
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

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _TipCard({required this.icon, required this.title, required this.body});

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

class LessonScreen extends StatefulWidget {
  final AppState appState;
  final int? lessonIndex;
  /// Track độc lập: 'Hán' hoặc 'Nôm'.
  final String trackType;
  /// Số bài trong track (1-based), không phải chỉ số toàn cục.
  final int? trackLessonNumber;
  final bool reviewMode;
  final bool isJumpAhead;
  /// Mốc ôn tập định kỳ (1-based); null khi là bài thường/ôn tập tự do.
  final int? checkpointIndex;
  /// Số bài 1-based cần mở khóa sau khi vượt qua bài thi.
  final int targetIndex;

  const LessonScreen({
    super.key,
    required this.appState,
    this.lessonIndex,
    this.trackType = 'Hán',
    this.trackLessonNumber,
    this.reviewMode = false,
    this.isJumpAhead = false,
    this.checkpointIndex,
    this.targetIndex = 1,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final List<HanCharacter> _characters;
  late final List<Question> _questions;
  late final bool _isActivePartLesson;
  late final int _lessonPart;

  bool get _isRegularHanLesson => widget.trackType == 'Hán' &&
      widget.trackLessonNumber != null &&
      !widget.reviewMode && !widget.isJumpAhead && widget.checkpointIndex == null;
  int _questionIndex = 0;
  String? _selectedOption;
  bool _checked = false;
  bool _isCorrect = false;
  bool _finishing = false;
  bool _outOfHeartsDialogOpen = false;
  bool _matchingMistakeCharged = false;
  final Set<String> _correctCharacters = {};
  final TextEditingController _typingController = TextEditingController();

  Question get _question => _questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _isActivePartLesson = _isRegularHanLesson && widget.trackLessonNumber == widget.appState.hanLessonsCompleted + 1;
    _lessonPart = _isActivePartLesson ? widget.appState.currentLessonPart : 1;
    if (widget.isJumpAhead) {
      // Lấy 10 chữ ngẫu nhiên từ các Node đứng trước bài mục tiêu; dùng cùng bộ câu hỏi Phần 3.
      _characters = randomJumpAheadCharacters(
        limit: 10,
        targetLessonNumber: widget.targetIndex,
      );
    } else if (widget.reviewMode && widget.checkpointIndex != null) {
      _characters = randomReviewCheckpointCharacters(checkpointNumber: widget.checkpointIndex!, limit: 20);
    } else if (widget.reviewMode) {
      final availableHanCount = widget.appState.hanLessonsCompleted > widget.appState.unlockedHanThroughLesson
          ? widget.appState.hanLessonsCompleted
          : widget.appState.unlockedHanThroughLesson;
      final availableUnits = widget.trackType == 'Nôm'
          ? nomLessonUnits.take(widget.appState.unlockedNomLessons)
          : hanLessonUnits.take(availableHanCount);
      final availableSymbols = availableUnits.expand((unit) => unit.characters).toSet();
      final availableCharacters = seedCharacters
          .where((character) => availableSymbols.contains(character.character))
          .toList();
      // Ưu tiên chữ chưa vững, nhưng xáo trộn trong cùng mức thuần thục để
      // mỗi lần ôn không lặp lại một danh sách cố định dễ đoán.
      final masteryBuckets = <int, List<HanCharacter>>{};
      for (final character in availableCharacters) {
        masteryBuckets.putIfAbsent(widget.appState.masteryOf(character.character), () => <HanCharacter>[])
            .add(character);
      }
      final reviewPool = <HanCharacter>[];
      final reviewRandom = Random();
      for (final level in masteryBuckets.keys.toList()..sort()) {
        final bucket = masteryBuckets[level]!..shuffle(reviewRandom);
        reviewPool.addAll(bucket);
      }
      // Buckets đã được xáo trộn bên trong từng mức mastery và thêm theo
      // thứ tự mastery thấp -> cao; không xáo/sort lần nữa để giữ ưu tiên đó.
      _characters = reviewPool.take(12).toList();
    } else if (widget.trackLessonNumber != null) {
      final unitIndex = widget.trackType == 'Nôm'
          ? hanCoreLessonCount + widget.trackLessonNumber! - 1
          : widget.trackLessonNumber! - 1;
      _characters = charactersForUnit(unitIndex);
    } else {
      _characters = charactersForUnit(widget.lessonIndex ?? 0);
    }
    final knownCharacters = _knownCharactersForQuestionGeneration();
    if (_isActivePartLesson) {
      _questions = generateLessonPartQuestions(
        _characters,
        part: _lessonPart,
        knownCharacters: knownCharacters,
        sentenceTypingLimit: _lessonPart == 3 ? 4 : 0,
      );
    } else if (widget.isJumpAhead) {
      _questions = generateAdvancedReviewQuestions(
        characters: _characters,
        knownCharacters: knownCharacters,
        mode: ReviewChallengeMode.jumpAhead,
      );
    } else if (widget.checkpointIndex != null) {
      _questions = generateAdvancedReviewQuestions(
        characters: _characters,
        knownCharacters: knownCharacters,
        mode: ReviewChallengeMode.checkpoint,
      );
    } else if (widget.reviewMode) {
      _questions = generateAdvancedReviewQuestions(
        characters: _characters,
        knownCharacters: knownCharacters,
        mode: ReviewChallengeMode.dailyReview,
      );
    } else {
      // Các bài được mở lại cũng dùng format Phần 3/3 thay vì generator cũ.
      _questions = generateLessonPartQuestions(
        _characters,
        part: 3,
        knownCharacters: knownCharacters,
        sentenceTypingLimit: 4,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.appState.hearts <= 0) _showOutOfHeartsDialog();
    });
  }

  List<HanCharacter> _knownCharactersForQuestionGeneration() {
    final knownBySymbol = <String, HanCharacter>{};

    void addSymbols(Iterable<String> symbols) {
      for (final symbol in symbols) {
        final character = findCharacter(symbol);
        if (character != null && character.isHan) knownBySymbol[symbol] = character;
      }
    }

    if (widget.trackType == 'Hán' && widget.trackLessonNumber != null) {
      final currentUnitIndex = (widget.trackLessonNumber! - 1).clamp(0, hanLessonUnits.length).toInt();
      addSymbols(hanLessonUnits.take(currentUnitIndex).expand((unit) => unit.characters));
      final partBeingStudied = _isActivePartLesson ? _lessonPart : 3;
      if (partBeingStudied == 1) {
        final splitAt = (_characters.length ~/ 2).clamp(1, _characters.length).toInt();
        addSymbols(_characters.take(splitAt).map((character) => character.character));
      } else {
        addSymbols(_characters.map((character) => character.character));
      }
    } else if (widget.isJumpAhead) {
      addSymbols(hanLessonUnits
          .take((widget.targetIndex - 1).clamp(0, hanLessonUnits.length).toInt())
          .expand((unit) => unit.characters));
    } else if (widget.checkpointIndex != null) {
      final firstUnit = (widget.checkpointIndex! - 1) * hanLessonsPerCycle;
      addSymbols(hanLessonUnits.skip(firstUnit).take(hanLessonsPerCycle).expand((unit) => unit.characters));
    } else if (widget.reviewMode) {
      final count = widget.appState.hanLessonsCompleted > widget.appState.unlockedHanThroughLesson
          ? widget.appState.hanLessonsCompleted
          : widget.appState.unlockedHanThroughLesson;
      addSymbols(hanLessonUnits.take(count).expand((unit) => unit.characters));
    } else if (widget.trackType == 'Hán' && widget.lessonIndex != null) {
      final currentUnitIndex = widget.lessonIndex!.clamp(0, hanLessonUnits.length - 1).toInt();
      addSymbols(hanLessonUnits.take(currentUnitIndex).expand((unit) => unit.characters));
      addSymbols(_characters.map((character) => character.character));
    } else {
      addSymbols(_characters.map((character) => character.character));
    }

    // Include sampled review/jump-ahead characters only if their curriculum
    // node is already in the known range above.
    return knownBySymbol.values.toList(growable: false);
  }

  String _normalizeAnswer(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[。．！？!?.,;:，；：、…]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<void> _checkAnswer() async {
    if (_selectedOption == null || _selectedOption!.trim().isEmpty || _checked) return;

    final typed = _normalizeAnswer(_selectedOption!);
    final accepted = _question.acceptedAnswers?.map(_normalizeAnswer).toList() ?? const <String>[];
    final isTypingQuestion = _question.type == QuestionType.typing ||
        _question.type == QuestionType.typingSentenceMeaning ||
        _question.type == QuestionType.typingSentenceReading;
    final correct = isTypingQuestion
        ? accepted.contains(typed) || typed == _normalizeAnswer(_question.correctAnswer)
        : (_question.type == QuestionType.translateSentence ||
                _question.type == QuestionType.translateHanVietToCharacter)
            ? typed == _normalizeAnswer(_question.correctAnswer)
            : _selectedOption == _question.correctAnswer;

    setState(() {
      _checked = true;
      _isCorrect = correct;
      if (correct) {
        if (_question.type == QuestionType.translateSentence ||
            _question.type == QuestionType.translateHanVietToCharacter ||
            _question.type == QuestionType.typingSentenceMeaning ||
            _question.type == QuestionType.typingSentenceReading) {
          _correctCharacters.addAll(_question.sentenceTokens?.map((token) => token.text) ?? <String>[_question.character]);
        } else {
          _correctCharacters.add(_question.character);
        }
      }
    });
    FocusManager.instance.primaryFocus?.unfocus();

    if (!correct) {
      await widget.appState.recordWrongAnswer();
      if (!mounted) return;
      setState(() {});
      if (widget.appState.hearts <= 0) await _showOutOfHeartsDialog();
    }
  }

  void _completeMatchingQuestion() {
    if (!mounted || _checked) return;
    setState(() {
      _selectedOption = _question.correctAnswer;
      _checked = true;
      _isCorrect = true;
      _correctCharacters.addAll(_question.matchingPairs?.keys ?? <String>[_question.character]);
    });
  }

  Future<void> _registerMatchingMistake() async {
    // Tránh trừ nhiều tim liên tiếp trong cùng một bài nối cặp.
    if (!mounted || _checked || _matchingMistakeCharged) return;
    _matchingMistakeCharged = true;
    await widget.appState.recordWrongAnswer();
    if (!mounted) return;
    setState(() {});
    if (widget.appState.hearts <= 0) await _showOutOfHeartsDialog();
  }

  Future<void> _showOutOfHeartsDialog() async {
    if (!mounted || _outOfHeartsDialogOpen || widget.appState.hearts > 0) return;
    _outOfHeartsDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AnimatedBuilder(
        animation: widget.appState,
        builder: (dialogContext, _) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.heart_broken_rounded, color: kRed, size: 48),
          title: const Text('Hết tim rồi!', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tim tự hồi khi bạn nghỉ học. Cứ mỗi 30 phút bạn sẽ nhận thêm 1 tim, kể cả khi đóng ứng dụng.', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              if (widget.appState.hearts == 0) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.schedule_rounded, color: kRed, size: 20),
                const SizedBox(width: 8),
                const Text('Tim tiếp theo sau ', style: TextStyle(color: Colors.black54)),
                _HeartCountdownText(appState: widget.appState, style: const TextStyle(fontWeight: FontWeight.w900, color: kRed)),
              ]) else ...[
                Text('Bạn đã hồi được ${widget.appState.hearts} tim.', textAlign: TextAlign.center, style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Tiếp tục học'),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await widget.appState.buyHearts(cost: 350, amount: 5);
                  if (!mounted) return;
                  if (success) {
                    Navigator.of(dialogContext).pop();
                    setState(() {});
                  } else {
                    showDialog<void>(
                      context: context,
                      builder: (messageContext) => AlertDialog(
                        title: const Text('Chưa đủ đá quý'),
                        content: const Text('Bạn cần 350 đá quý để nạp đầy 5 tim.'),
                        actions: [TextButton(onPressed: () => Navigator.of(messageContext).pop(), child: const Text('Đã hiểu'))],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.diamond_rounded),
                label: const Text('Nạp đầy 5 tim · 350 đá quý'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AlertDialog(
                      content: Row(children: [CircularProgressIndicator(), SizedBox(width: 18), Expanded(child: Text('Đang xem quảng cáo giả lập...'))]),
                    ),
                  );
                  await Future<void>.delayed(const Duration(seconds: 2));
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  await widget.appState.addHeart(1);
                  if (!mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nhận +1 tim! ❤️')));
                },
                icon: const Icon(Icons.ondemand_video_rounded),
                label: const Text('Xem quảng cáo giả lập · +1 tim'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Thoát bài học', style: TextStyle(color: kRed, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
    _outOfHeartsDialogOpen = false;
  }

  Future<void> _nextQuestion() async {
    if (!_checked) return;
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedOption = null;
        _checked = false;
        _isCorrect = false;
        _matchingMistakeCharged = false;
        _typingController.clear();
      });
      return;
    }
    await _finishLesson();
  }

  Future<void> _finishLesson() async {
    if (_finishing) return;
    _finishing = true;
    await widget.appState.finishLesson(
      // The separate-track lesson number is authoritative for new screens;
      // lessonIndex is retained only for older callers.
      lessonIndex: widget.trackLessonNumber != null || widget.reviewMode || widget.isJumpAhead
          ? null
          : widget.lessonIndex,
      trackType: widget.trackType,
      trackLessonNumber: widget.reviewMode || widget.isJumpAhead || widget.checkpointIndex != null
          ? null
          : widget.trackLessonNumber,
      masteredCharacters: _correctCharacters,
      xpReward: widget.isJumpAhead ? 50 : _isActivePartLesson ? 15 : 20,
      lessonPart: _isActivePartLesson ? _lessonPart : null,
      unlockTargetLessonNumber: widget.isJumpAhead ? widget.targetIndex : null,
      reviewCheckpointNumber: widget.checkpointIndex,
    );
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(widget.isJumpAhead ? Icons.rocket_launch_rounded : widget.checkpointIndex != null ? Icons.workspace_premium_rounded : Icons.celebration_rounded, color: kOrange, size: 52),
        title: Text(
          widget.isJumpAhead ? 'Nhảy cóc thành công! 🚀'
              : widget.checkpointIndex != null ? 'Tổng Ôn tập hoàn thành! 🏆'
              : widget.reviewMode ? 'Ôn tập hoàn tất!'
              : _isActivePartLesson ? 'Hoàn thành Phần $_lessonPart/3! 🎉'
              : 'Hoàn thành bài học!',
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Bạn trả lời đúng ${_correctCharacters.length} chữ khác nhau.'),
          const SizedBox(height: 10),
          Text(
            widget.isJumpAhead
                ? 'Bạn đã mở khóa Bài ${widget.targetIndex}!\n+50 XP     +5 đá quý'
                : widget.checkpointIndex != null
                    ? 'Bạn đã hoàn thành Tổng Ôn tập ${widget.checkpointIndex} và mở cụm bài tiếp theo!\n+20 XP     +5 đá quý'
                    : _isActivePartLesson
                        ? (_lessonPart < 3
                            ? 'Phần ${_lessonPart + 1}/3 đã được mở khóa. Quay về lộ trình để tiếp tục bài học.\n+15 XP     +5 đá quý'
                            : ((widget.trackLessonNumber ?? 0) % hanLessonsPerCycle == 0
                                ? 'Bạn đã hoàn tất đủ 3 phần! Tổng Ôn tập đã mở khóa.\n+15 XP     +5 đá quý'
                                : 'Bạn đã hoàn tất đủ 3 phần và mở khóa bài tiếp theo!\n+15 XP     +5 đá quý'))
                        : '+20 XP     +5 đá quý',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ]),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(_isActivePartLesson ? 'Về lộ trình' : 'Tiếp tục'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: kPaper,
        appBar: AppBar(backgroundColor: kPaper, title: const Text('Chưa có bài để ôn')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Hãy hoàn thành một bài học trước. Các câu dịch chỉ xuất hiện khi có cụm/câu phù hợp và toàn bộ chữ đã được học.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
      );
    }
    final question = _question;
    final character = findCharacter(question.character);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: (_questionIndex + 1) / _questions.length, minHeight: 9, backgroundColor: const Color(0xFFE0E7DF), color: kGreen),
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 15), child: _HeartAppBarStatus(appState: widget.appState)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                children: [
                  Text(
                    widget.isJumpAhead
                        ? 'BÀI THI HỌC VƯỢT · MỞ KHÓA BÀI ${widget.targetIndex}'
                        : widget.checkpointIndex != null
                            ? 'TỔNG ÔN TẬP ${widget.checkpointIndex}'
                            : widget.reviewMode
                                ? 'ÔN TẬP CÁ NHÂN'
                                : widget.trackLessonNumber != null
                                    ? '${widget.trackType == 'Nôm' ? 'CHỮ NÔM' : 'HÁN TỰ'} · BÀI ${widget.trackLessonNumber}${_isActivePartLesson ? ' · PHẦN $_lessonPart/3' : ''}'
                                    : 'BÀI ${(widget.lessonIndex ?? 0) + 1}',
                    style: const TextStyle(color: kGreen, letterSpacing: 1.2, fontWeight: FontWeight.w900, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 7),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1D7), borderRadius: BorderRadius.circular(12)),
                    child: Text(question.sectionTitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9A5A20), fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  Center(child: TypeBadge(type: question.characterType, compact: true)),
                  const SizedBox(height: 14),
                  Text(question.prompt, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, height: 1.2, color: Color(0xFF20372C), fontFamilyFallback: ['NomNaTong', 'HanNomB']), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (question.type == QuestionType.introduceWord)
                    IntroduceWordWidget(
                      key: ValueKey('introduce-word-$_questionIndex'),
                      question: question,
                      selectedAnswer: _selectedOption,
                      enabled: !_checked && widget.appState.hearts > 0,
                      supplementaryLanguage: widget.appState.supplementaryLanguage,
                      cjkCharacters: widget.appState.cjkCharacters,
                      onSelected: (answer) {
                        if (!_checked) setState(() => _selectedOption = answer);
                      },
                    )
                  else if (question.type == QuestionType.fillInTheBlank && question.sentenceTokens != null)
                    FillInTheBlankWidget(
                      tokens: question.sentenceTokens!,
                      options: question.options,
                      selectedAnswer: _selectedOption,
                      correctAnswer: question.correctAnswer,
                      checked: _checked,
                      isCorrect: _isCorrect,
                      onSelected: (answer) => setState(() => _selectedOption = answer),
                    )
                  else if (question.type == QuestionType.matchingPairs)
                    MatchingPairsWidget(
                      key: ValueKey('matching-question-$_questionIndex'),
                      pairs: question.matchingPairs ?? const <String, String>{},
                      enabled: !_checked && widget.appState.hearts > 0,
                      onComplete: _completeMatchingQuestion,
                      onMistake: _registerMatchingMistake,
                    )
                  else if (question.type == QuestionType.translateSentence ||
                      question.type == QuestionType.translateHanVietToCharacter)
                    TranslateSentenceWidget(
                      key: ValueKey('translate-question-$_questionIndex'),
                      question: question,
                      reverseDirection: question.type == QuestionType.translateHanVietToCharacter,
                      enabled: !_checked,
                      onAnswerChanged: (answer) {
                        if (!_checked) setState(() => _selectedOption = answer);
                      },
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(minHeight: 172),
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: question.characterType == 'Nôm' ? kNomLight : kGreenLight, borderRadius: BorderRadius.circular(24)),
                      alignment: Alignment.center,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(
                          question.type == QuestionType.character
                              ? (character?.meaning ?? '')
                              : (question.type == QuestionType.typingSentenceMeaning ||
                                      question.type == QuestionType.typingSentenceReading)
                                  ? (question.sourceText ?? question.character)
                                  : question.character,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: question.type == QuestionType.character
                                ? 26
                                : (question.type == QuestionType.typingSentenceMeaning ||
                                        question.type == QuestionType.typingSentenceReading)
                                    ? 44
                                    : 82,
                            height: (question.type == QuestionType.typingSentenceMeaning ||
                                    question.type == QuestionType.typingSentenceReading) ? 1.45 : null,
                            color: question.characterType == 'Nôm' ? kOrange : kGreen,
                            fontWeight: FontWeight.w700,
                            fontFamilyFallback: const ['NomNaTong', 'HanNomB'],
                          ),
                        ),
                        if (question.type == QuestionType.radical) ...[
                          const SizedBox(height: 8),
                          Text(question.characterType == 'Nôm' ? 'Cách đọc: ${character?.hanVietReading ?? ''}' : 'Âm Hán-Việt: ${character?.hanVietReading ?? ''}', style: const TextStyle(color: kOrange, fontWeight: FontWeight.w800)),
                        ],
                        if (question.type == QuestionType.typing ||
                            question.type == QuestionType.typingSentenceMeaning ||
                            question.type == QuestionType.typingSentenceReading) ...[
                          const SizedBox(height: 8),
                          Text(
                            question.type == QuestionType.typingSentenceReading
                                ? 'Tự gõ âm Hán-Việt; nghĩa tiếng Việt sẽ hiện sau khi kiểm tra'
                                : question.type == QuestionType.typingSentenceMeaning
                                    ? 'Tự dịch cả câu, không có gợi ý đáp án'
                                    : 'Hãy tự nhớ âm đọc hoặc nghĩa',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 18),
                  if (question.type == QuestionType.typing ||
                      question.type == QuestionType.typingSentenceMeaning ||
                      question.type == QuestionType.typingSentenceReading) ...[
                    TextField(
                      controller: _typingController,
                      enabled: !_checked,
                      autofocus: false,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        hintText: question.type == QuestionType.typingSentenceReading
                            ? 'Gõ âm Hán-Việt của cả câu…'
                            : question.type == QuestionType.typingSentenceMeaning
                                ? 'Gõ nghĩa tiếng Việt của cả câu…'
                                : question.characterType == 'Nôm'
                                    ? 'Nhập cách đọc tiếng Việt hoặc nghĩa…'
                                    : 'Nhập âm Hán-Việt hoặc nghĩa…',
                        filled: true,
                        fillColor: _checked ? (_isCorrect ? const Color(0xFFE4F5E8) : const Color(0xFFFFE9E7)) : Colors.white,
                      ),
                      onChanged: (value) => setState(() => _selectedOption = value),
                      onSubmitted: (_) { if (!_checked) _checkAnswer(); },
                    ),
                  ] else if (question.type != QuestionType.introduceWord &&
                      question.type != QuestionType.typingSentenceMeaning &&
                      question.type != QuestionType.typingSentenceReading &&
                      question.type != QuestionType.fillInTheBlank &&
                      question.type != QuestionType.matchingPairs &&
                      question.type != QuestionType.translateSentence &&
                      question.type != QuestionType.translateHanVietToCharacter) ...[
                    Text(
                      question.type == QuestionType.radical ? (question.characterType == 'Nôm' ? 'CHỌN THÀNH PHẦN GỢI NGHĨA' : 'CHỌN BỘ THỦ') : 'CHỌN MỘT ĐÁP ÁN',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: Colors.black45),
                    ),
                    const SizedBox(height: 10),
                    for (var index = 0; index < question.options.length; index++)
                      _AnswerOption(
                        label: question.options[index],
                        letter: String.fromCharCode(65 + index),
                        selected: _selectedOption == question.options[index],
                        checked: _checked,
                        correct: question.options[index] == question.correctAnswer,
                        onTap: _checked ? null : () => setState(() => _selectedOption = question.options[index]),
                      ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: _checked ? (_isCorrect ? const Color(0xFFEAF7ED) : const Color(0xFFFFF0EB)) : Colors.white,
                border: Border(top: BorderSide(color: _checked ? (_isCorrect ? const Color(0xFFBFE2C7) : const Color(0xFFFFC9BB)) : const Color(0xFFE8ECE7), width: 1.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                if (_checked) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_isCorrect ? Icons.check_circle_rounded : Icons.auto_awesome_rounded, color: _isCorrect ? kGreen : kOrange, size: 28),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      question.type == QuestionType.typingSentenceReading
                          ? (_isCorrect
                              ? 'Chính xác! Âm Hán-Việt đúng.'
                              : 'Chưa đúng. Âm Hán-Việt chính xác: ${question.correctAnswer}')
                          : _isCorrect
                              ? 'Chính xác! Xuất sắc.'
                              : (question.type == QuestionType.typing || question.type == QuestionType.typingSentenceMeaning)
                                  ? 'Đáp án đúng: ${(question.acceptedAnswers ?? [question.correctAnswer]).join(" / ")}'
                                  : 'Chưa đúng. Đáp án là: ${question.correctAnswer}',
                      style: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w900, color: _isCorrect ? kGreen : const Color(0xFF9E422E)),
                    )),
                  ]),
                  if (question.type == QuestionType.typingSentenceReading &&
                      (question.meaningExplanation ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD5E8DA)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.translate_rounded, color: kGreen, size: 21),
                        const SizedBox(width: 9),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('NGHĨA TIẾNG VIỆT THAM KHẢO', style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w900, color: kGreen)),
                          const SizedBox(height: 4),
                          Text(question.meaningExplanation!, style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w700, color: Color(0xFF263A2F))),
                          const SizedBox(height: 3),
                          const Text('Nghĩa có thể được diễn đạt theo nhiều cách; phần này dùng để tham khảo, không phải đáp án bạn cần gõ.', style: TextStyle(fontSize: 11, height: 1.35, color: Colors.black54)),
                        ])),
                      ]),
                    ),
                  ],
                  if (question.type != QuestionType.typingSentenceReading && !_isCorrect && question.mnemonic != null && question.mnemonic!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFF0DDA8))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.lightbulb_rounded, color: Color(0xFFB98216), size: 21),
                        const SizedBox(width: 8),
                        Expanded(child: Text(question.mnemonic!, style: const TextStyle(fontSize: 13, height: 1.4, fontStyle: FontStyle.italic, color: Color(0xFF5E4A25)))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 13),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _checked ? (_isCorrect ? kGreen : kOrange) : kGreen, foregroundColor: Colors.white),
                    onPressed: _checked
                        ? _nextQuestion
                        : (_selectedOption == null || _selectedOption!.trim().isEmpty ? null : _checkAnswer),
                    child: Text(_checked
                      ? (_questionIndex == _questions.length - 1 ? 'Hoàn thành' : 'Tiếp tục')
                      : question.type == QuestionType.typingSentenceReading
                          ? 'Kiểm tra âm Hán-Việt'
                          : question.type == QuestionType.typingSentenceMeaning
                          ? 'Kiểm tra bản dịch'
                          : question.type == QuestionType.typing
                              ? 'Kiểm tra đáp án'
                              : question.type == QuestionType.matchingPairs
                                  ? 'Nối hết các cặp để tiếp tục'
                                  : question.type == QuestionType.translateHanVietToCharacter
                                      ? 'Kiểm tra chữ Hán'
                                      : question.type == QuestionType.translateSentence
                                          ? 'Kiểm tra âm Hán-Việt'
                                          : question.type == QuestionType.introduceWord
                                              ? 'Kiểm tra nghĩa'
                                              : 'Kiểm tra'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;
  final String letter;
  final bool selected;
  final bool checked;
  final bool correct;
  final VoidCallback? onTap;
  const _AnswerOption({required this.label, required this.letter, required this.selected, required this.checked, required this.correct, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color background = Colors.white;
    Color border = const Color(0xFFE1E7E0);
    Color textColor = const Color(0xFF263A2F);
    if (checked && correct) {
      background = const Color(0xFFE3F3E7);
      border = kGreen;
      textColor = kGreen;
    } else if (checked && selected && !correct) {
      background = const Color(0xFFFFE9E7);
      border = kRed;
      textColor = kRed;
    } else if (selected) {
      background = kGreenLight;
      border = kGreen;
      textColor = kGreen;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: selected || (checked && correct) ? 1.7 : 1)),
            child: Row(children: [
              Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? border.withOpacity(0.12) : const Color(0xFFF2F4F0), borderRadius: BorderRadius.circular(10)), child: Text(letter, style: TextStyle(fontWeight: FontWeight.w900, color: textColor))),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 16, fontFamilyFallback: const ['NomNaTong', 'HanNomB']))),
              if (checked && correct) const Icon(Icons.check_circle_rounded, color: kGreen),
            ]),
          ),
        ),
      ),
    );
  }
}
