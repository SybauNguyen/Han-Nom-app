import 'dart:async';

import 'package:flutter/material.dart';

import 'core/database/database_service.dart';
import 'core/theme/app_colors.dart';
import 'data/models/cjk_character.dart';
import 'screens/dictionary_screen.dart';
import 'screens/han_track_screen.dart';
import 'screens/nom_track_screen.dart';
import 'screens/profile_screen.dart';
import 'services/tts_service.dart';
import 'state/app_state.dart';
import 'widgets/stats_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TtsService.instance.init();
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
    TtsService.instance.stop();
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
              LanguageFlagBadge(flag: language.flagEmoji, width: 48, height: 40),
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
