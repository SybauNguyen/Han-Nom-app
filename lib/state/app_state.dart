import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/han_seed_data.dart';
import '../data/legacy_nom_codepoints.dart';
import '../data/models/cjk_character.dart';

/// Chuỗi ngày dùng ngày lịch địa phương, không phụ thuộc giờ/phút.
int calculateStreakAfterStudy({
  required int currentStreak,
  required DateTime? lastActivity,
  required DateTime now,
}) {
  if (lastActivity == null) return 1;
  final difference = _calendarDayDifference(now, lastActivity);
  if (difference <= 0) return currentStreak;
  if (difference == 1) return currentStreak + 1;
  return 1;
}

int _calendarDayDifference(DateTime newer, DateTime older) {
  final localNewer = newer.toLocal();
  final localOlder = older.toLocal();
  final newerDay = DateTime.utc(localNewer.year, localNewer.month, localNewer.day);
  final olderDay = DateTime.utc(localOlder.year, localOlder.month, localOlder.day);
  return newerDay.difference(olderDay).inDays;
}

class AppState extends ChangeNotifier {
  static const int maxHearts = 5;
  static const Duration heartRegenInterval = Duration(minutes: 30);

  Timer? _heartRegenTimer;
  bool _isDisposed = false;
  bool _savingRegen = false;

  int xp = 0;
  int streak = 0;
  int gems = 500;
  int hearts = 5;
  DateTime? lastHeartRegenTime;

  /// Ngôn ngữ đọc bổ sung: mặc định tắt để giữ trải nghiệm nguyên bản của v2.6.
  SupplementaryLanguage supplementaryLanguage = SupplementaryLanguage.none;
  /// True after the first-run language picker was completed or skipped.
  bool hasSeenSupplementaryLanguagePrompt = false;

  /// Số giây còn lại đến tim tự hồi kế tiếp; null khi đầy tim hoặc chưa có mốc.
  int? get heartRegenSecondsRemaining {
    if (hearts >= maxHearts || lastHeartRegenTime == null) return null;
    final elapsed = DateTime.now().difference(lastHeartRegenTime!).inSeconds;
    return (heartRegenInterval.inSeconds - elapsed).clamp(0, heartRegenInterval.inSeconds).toInt();
  }

  /// Tiến độ hai luồng độc lập. Bài ôn tập không tăng số bài học mới.
  int hanLessonsCompleted = 0;
  /// Phần tiếp theo của bài Hán đang học (1–3). Chỉ chuyển sang bài mới sau phần 3.
  int currentLessonPart = 1;
  int nomLessonsCompleted = 0;
  int completedHanReviewCheckpoints = 0;
  int unlockedHanThroughLesson = 0;

  Map<String, int> mastery = {};
  final Map<String, CjkCharacter> _cjkCharacters = <String, CjkCharacter>{};

  List<CjkCharacter> get cjkCharacters => List<CjkCharacter>.unmodifiable(_cjkCharacters.values);

  CjkCharacter? cjkCharacterFor(String character) {
    final query = character.trim();
    final exact = _cjkCharacters[query];
    if (exact != null) return exact;
    for (final record in _cjkCharacters.values) {
      if (record.charSimplified == query || record.charShinjitai == query) return record;
    }
    return null;
  }

  void setCjkCharacters(Iterable<CjkCharacter> characters) {
    _cjkCharacters
      ..clear()
      ..addEntries(characters.map((record) => MapEntry(record.charTraditional, record)));
    notifyListeners();
  }
  DateTime? lastActivity;
  String? lastStudyDate;
  bool isReady = false;

  int get level => (xp ~/ 100) + 1;
  int get xpInLevel => xp % 100;
  int get completedLessons => hanLessonsCompleted + nomLessonsCompleted;
  int get completedReviewCheckpoints => completedHanReviewCheckpoints;
  int get unlockedThroughLesson => unlockedHanThroughLesson;
  int get unlockedLessons => (hanLessonsCompleted + 1).clamp(1, hanCoreLessonCount).toInt();
  bool get hasCompletedHanCore => hanLessonsCompleted >= hanCoreLessonCount;
  int get unlockedNomLessons => completedHanReviewCheckpoints.clamp(0, nomTrackLessonCount).toInt();

  bool isHanLessonUnlocked(int lessonNumber) {
    if (lessonNumber < 1 || lessonNumber > hanCoreLessonCount) return false;
    if (lessonNumber <= hanLessonsCompleted || lessonNumber <= unlockedHanThroughLesson) return true;
    if (lessonNumber != hanLessonsCompleted + 1) return false;
    // Lesson 6/11/16/... is behind the previous Boss checkpoint.
    final requiredCheckpoint = (lessonNumber - 1) ~/ hanLessonsPerCycle;
    return completedHanReviewCheckpoints >= requiredCheckpoint;
  }

  bool isHanReviewCheckpointUnlocked(int checkpointNumber) {
    if (checkpointNumber < 1 || checkpointNumber > hanCoreLessonCount ~/ hanLessonsPerCycle) return false;
    if (checkpointNumber <= completedHanReviewCheckpoints) return true;
    return checkpointNumber == completedHanReviewCheckpoints + 1 &&
        hanLessonsCompleted >= checkpointNumber * hanLessonsPerCycle;
  }

  bool isHanReviewCheckpointCompleted(int checkpointNumber) =>
      checkpointNumber > 0 && checkpointNumber <= completedHanReviewCheckpoints;

  bool isNomLessonUnlocked(int lessonNumber) {
    if (lessonNumber < 1 || lessonNumber > nomTrackLessonCount) return false;
    if (lessonNumber <= nomLessonsCompleted) return true;
    // One Nôm lesson unlocks after the corresponding Hán Boss has been passed.
    return lessonNumber == nomLessonsCompleted + 1 &&
        completedHanReviewCheckpoints >= lessonNumber;
  }

  /// Backward-compatible index API for older screens: global zero-based lesson index.
  bool isLessonUnlocked(int index) {
    if (index < 0 || index >= lessonUnits.length) return false;
    if (index < hanCoreLessonCount) return isHanLessonUnlocked(index + 1);
    return isNomLessonUnlocked(index - hanCoreLessonCount + 1);
  }

  bool isReviewCheckpointUnlocked(int checkpointNumber) =>
      isHanReviewCheckpointUnlocked(checkpointNumber);

  bool isReviewCheckpointCompleted(int checkpointNumber) =>
      isHanReviewCheckpointCompleted(checkpointNumber);

  Future<void> setSupplementaryLanguage(SupplementaryLanguage language) async {
    final changed = supplementaryLanguage != language;
    supplementaryLanguage = language;
    // Editing this setting in Profile also counts as completing onboarding.
    final promptChanged = !hasSeenSupplementaryLanguagePrompt;
    hasSeenSupplementaryLanguagePrompt = true;
    if (changed || promptChanged) notifyListeners();
    await _save();
  }

  /// Finish the first-run picker. A null selection means the learner skipped;
  /// the current language setting is then left unchanged.
  Future<void> finishSupplementaryLanguagePrompt({SupplementaryLanguage? selection}) async {
    if (selection != null) supplementaryLanguage = selection;
    hasSeenSupplementaryLanguagePrompt = true;
    notifyListeners();
    await _save();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      xp = prefs.getInt('xp') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
      gems = prefs.getInt('gems') ?? 500;
      if (!(prefs.getBool('heartShopMigrationV2') ?? false)) {
        if (gems < 500) gems = 500;
        await prefs.setInt('gems', gems);
        await prefs.setBool('heartShopMigrationV2', true);
      }
      hearts = (prefs.getInt('hearts') ?? 5).clamp(0, maxHearts).toInt();
      lastHeartRegenTime = DateTime.tryParse(prefs.getString('lastHeartRegenTime') ?? '')?.toLocal();

      currentLessonPart = (prefs.getInt('currentLessonPart') ?? 1).clamp(1, 3).toInt();
      hasSeenSupplementaryLanguagePrompt = prefs.getBool('supplementaryLanguagePromptSeen') ?? false;
      final savedSupplementaryLanguage = prefs.getString('supplementaryLanguage');
      supplementaryLanguage = SupplementaryLanguage.values.firstWhere(
        (language) => language.name == savedSupplementaryLanguage,
        orElse: () => SupplementaryLanguage.none,
      );

      final legacyCompleted = prefs.getInt('completedLessons') ?? 0;
      final legacyCheckpoints = prefs.getInt('completedReviewCheckpoints') ?? 0;
      if (prefs.getBool('separateTracksV1') ?? false) {
        hanLessonsCompleted = (prefs.getInt('hanLessonsCompleted') ?? 0).clamp(0, hanCoreLessonCount).toInt();
        nomLessonsCompleted = (prefs.getInt('nomLessonsCompleted') ?? 0).clamp(0, nomTrackLessonCount).toInt();
        completedHanReviewCheckpoints = (prefs.getInt('completedHanReviewCheckpoints') ?? legacyCheckpoints)
            .clamp(0, hanCoreLessonCount ~/ hanLessonsPerCycle).toInt();
        unlockedHanThroughLesson = (prefs.getInt('unlockedHanThroughLesson') ?? prefs.getInt('unlockedThroughLesson') ?? 0)
            .clamp(0, hanCoreLessonCount).toInt();
      } else {
        // Legacy single-roadmap schema used 50 Hán Nodes + 6 Nôm Nodes.
        // Convert directly to the current 25 Hán + 3 Nôm thematic roadmap;
        // do not let the later v2.4 migration halve this already-converted data.
        final oldHanCompleted = legacyCompleted.clamp(0, 50).toInt();
        final oldNomCompleted = (legacyCompleted - 50).clamp(0, 6).toInt();
        final oldBossesCompleted = (prefs.getInt('completedReviewCheckpoints') ?? (oldHanCompleted ~/ 5))
            .clamp(0, 10).toInt();
        final oldUnlockedHan = (prefs.getInt('unlockedThroughLesson') ?? 0).clamp(0, 50).toInt();

        hanLessonsCompleted = ((oldHanCompleted * 5) ~/ 10).clamp(0, hanCoreLessonCount).toInt();
        nomLessonsCompleted = ((oldNomCompleted * 5) ~/ 10).clamp(0, nomTrackLessonCount).toInt();
        completedHanReviewCheckpoints = ((oldBossesCompleted * 5) ~/ 10)
            .clamp(0, hanCoreLessonCount ~/ hanLessonsPerCycle)
            .clamp(0, hanLessonsCompleted ~/ hanLessonsPerCycle).toInt();
        unlockedHanThroughLesson = ((oldUnlockedHan * 5) ~/ 10).clamp(0, hanCoreLessonCount).toInt();
        if (unlockedHanThroughLesson < hanLessonsCompleted) {
          unlockedHanThroughLesson = hanLessonsCompleted;
        }
        currentLessonPart = 1;
        await prefs.setBool('separateTracksV1', true);
        await prefs.setBool('thematicCurriculumV3', true);
      }

      final savedActivity = prefs.getString('lastActivity');
      final legacyStudyDate = prefs.getString('lastStudyDate');
      lastActivity = DateTime.tryParse(savedActivity ?? '') ?? DateTime.tryParse(legacyStudyDate ?? '');
      lastStudyDate = lastActivity == null ? legacyStudyDate : _dateKey(lastActivity!.toLocal());
      if (lastActivity != null) {
        await prefs.setString('lastActivity', lastActivity!.toIso8601String());
        await prefs.setString('lastStudyDate', lastStudyDate!);
      }
      if (lastActivity != null && _calendarDayDifference(DateTime.now(), lastActivity!) > 1) {
        streak = 0;
        await prefs.setInt('streak', streak);
      }
      final rawMastery = prefs.getString('mastery');
      if (rawMastery != null) {
        final decoded = jsonDecode(rawMastery) as Map<String, dynamic>;
        mastery = decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
      // One-time curriculum migration: v2.3 had 50 Han Nodes x 5 chars and
      // 6 Nom Nodes; v2.4 reorganizes the same 250 Han characters into 25
      // thematic Nodes x 10. Preserve approximate character-count progress.
      if (!(prefs.getBool('thematicCurriculumV3') ?? false)) {
        final hadSeparateTracks = prefs.getBool('separateTracksV1') ?? false;
        final int oldHanCompleted;
        final int oldNomCompleted;
        final int oldBossesCompleted;
        final int oldUnlockedHan;
        if (hadSeparateTracks) {
          oldHanCompleted = (prefs.getInt('hanLessonsCompleted') ?? 0).clamp(0, 50).toInt();
          oldNomCompleted = (prefs.getInt('nomLessonsCompleted') ?? 0).clamp(0, 6).toInt();
          oldBossesCompleted = (prefs.getInt('completedHanReviewCheckpoints') ??
                  prefs.getInt('completedReviewCheckpoints') ?? (oldHanCompleted ~/ 5))
              .clamp(0, 10).toInt();
          oldUnlockedHan = (prefs.getInt('unlockedHanThroughLesson') ??
                  prefs.getInt('unlockedThroughLesson') ?? 0)
              .clamp(0, 50).toInt();
        } else {
          final oldCombinedCompleted = (prefs.getInt('completedLessons') ?? 0).clamp(0, 56).toInt();
          oldHanCompleted = oldCombinedCompleted.clamp(0, 50).toInt();
          oldNomCompleted = (oldCombinedCompleted - 50).clamp(0, 6).toInt();
          oldBossesCompleted = (prefs.getInt('completedReviewCheckpoints') ?? (oldHanCompleted ~/ 5))
              .clamp(0, 10).toInt();
          oldUnlockedHan = (prefs.getInt('unlockedThroughLesson') ?? 0).clamp(0, 50).toInt();
        }
        hanLessonsCompleted = ((oldHanCompleted * 5) ~/ 10).clamp(0, hanCoreLessonCount).toInt();
        nomLessonsCompleted = ((oldNomCompleted * 5) ~/ 10).clamp(0, nomTrackLessonCount).toInt();
        completedHanReviewCheckpoints = ((oldBossesCompleted * 5) ~/ 10)
            .clamp(0, hanCoreLessonCount ~/ hanLessonsPerCycle)
            .clamp(0, hanLessonsCompleted ~/ hanLessonsPerCycle).toInt();
        unlockedHanThroughLesson = ((oldUnlockedHan * 5) ~/ 10)
            .clamp(0, hanCoreLessonCount).toInt();
        if (unlockedHanThroughLesson < hanLessonsCompleted) {
          unlockedHanThroughLesson = hanLessonsCompleted;
        }
        // Part divisions and topics changed, so reopen the current Node at Part 1.
        currentLessonPart = 1;
        await prefs.setBool('thematicCurriculumV3', true);
      }

      if (!isNomDataEnabled) {
        // Xóa tiến độ/độ thuần thục gắn với các mục Nôm cũ đã bị gỡ khỏi seed.
        // XP, tim, đá quý, chuỗi ngày và tiến độ Hán được giữ nguyên.
        nomLessonsCompleted = 0;
        mastery.removeWhere((character, _) => retiredNomCodepoints.contains(character));
      }

      // Migration mềm: bản cũ chưa có mốc hồi tim. Nếu đang thiếu tim, bắt đầu từ lúc nâng cấp,
      // không tự thưởng thời gian hồi không có dữ liệu nguồn.
      if (hearts < maxHearts && lastHeartRegenTime == null) {
        lastHeartRegenTime = DateTime.now();
      }
      _applyHeartRegeneration(DateTime.now());
      await _save();
    } catch (_) {
      // Nếu dữ liệu phiên bản cũ lỗi, vẫn mở app với trạng thái mặc định.
    }
    isReady = true;
    _startHeartRegenTimer();
    notifyListeners();
  }

  int masteryOf(String character) => mastery[character] ?? 0;

  Future<void> recordWrongAnswer() async {
    // Xử lý tim vừa hồi đúng thời điểm trước khi trừ tim mới.
    await refreshHeartRegeneration();
    if (hearts > 0) {
      final wasFull = hearts >= maxHearts;
      hearts--;
      if (wasFull || lastHeartRegenTime == null) {
        lastHeartRegenTime = DateTime.now();
      }
    }
    _normalizeHeartRegenAnchor();
    await _save();
    notifyListeners();
  }

  Future<void> restoreHeart() async {
    await refreshHeartRegeneration();
    if (hearts >= maxHearts || gems < 50) return;
    gems -= 50;
    hearts++;
    _normalizeHeartRegenAnchor();
    await _save();
    notifyListeners();
  }

  Future<bool> buyHearts({required int cost, required int amount}) async {
    await refreshHeartRegeneration();
    if (gems < cost || hearts >= maxHearts || amount <= 0) return false;
    gems -= cost;
    hearts = (hearts + amount).clamp(0, maxHearts).toInt();
    _normalizeHeartRegenAnchor();
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> addHeart(int amount) async {
    await refreshHeartRegeneration();
    if (amount <= 0 || hearts >= maxHearts) return;
    hearts = (hearts + amount).clamp(0, maxHearts).toInt();
    _normalizeHeartRegenAnchor();
    await _save();
    notifyListeners();
  }

  /// Tính hồi tim dựa trên thời gian thực; được gọi khi mở app, resume, và khi app đang mở.
  /// Không có background service: nếu app tắt, mốc thời gian vẫn được lưu để bù khi mở lại.
  Future<void> refreshHeartRegeneration() async {
    if (!isReady || _isDisposed) return;
    if (_applyHeartRegeneration(DateTime.now())) {
      await _save();
      if (!_isDisposed) notifyListeners();
    }
  }

  void _startHeartRegenTimer() {
    _heartRegenTimer?.cancel();
    _heartRegenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed || !isReady || hearts >= maxHearts || lastHeartRegenTime == null || _savingRegen) return;
      if (!_applyHeartRegeneration(DateTime.now())) return;
      _savingRegen = true;
      unawaited(_save().whenComplete(() {
        _savingRegen = false;
        if (!_isDisposed) notifyListeners();
      }));
    });
  }

  /// Trả true nếu tim hoặc mốc hồi tim đã thay đổi.
  bool _applyHeartRegeneration(DateTime now) {
    var changed = false;
    if (hearts >= maxHearts) {
      if (lastHeartRegenTime != null) {
        lastHeartRegenTime = null;
        changed = true;
      }
      return changed;
    }

    if (lastHeartRegenTime == null) {
      lastHeartRegenTime = now;
      return true;
    }

    final elapsedSeconds = now.difference(lastHeartRegenTime!).inSeconds;
    if (elapsedSeconds < 0) {
      // Đồng hồ thiết bị bị chỉnh lùi: đặt lại mốc để tránh thời gian âm kéo dài vô hạn.
      lastHeartRegenTime = now;
      return true;
    }
    final heartsEarned = elapsedSeconds ~/ heartRegenInterval.inSeconds;
    if (heartsEarned <= 0) return false;

    final previousHearts = hearts;
    hearts = (hearts + heartsEarned).clamp(0, maxHearts).toInt();
    changed = hearts != previousHearts;
    if (hearts >= maxHearts) {
      lastHeartRegenTime = null;
      changed = true;
    } else {
      // Giữ lại phần thời gian dư, ví dụ 35 phút thì được +1 tim và còn 5 phút.
      lastHeartRegenTime = lastHeartRegenTime!.add(
        Duration(seconds: heartsEarned * heartRegenInterval.inSeconds),
      );
      changed = true;
    }
    return changed;
  }

  void _normalizeHeartRegenAnchor() {
    if (hearts >= maxHearts) {
      lastHeartRegenTime = null;
    } else {
      lastHeartRegenTime ??= DateTime.now();
    }
  }

  Future<void> finishLesson({
    required int? lessonIndex,
    required Set<String> masteredCharacters,
    String trackType = 'Hán',
    int? trackLessonNumber,
    int xpReward = 20,
    int? unlockTargetLessonNumber,
    DateTime? completedAt,
    int? reviewCheckpointNumber,
    int? lessonPart,
  }) async {
    if (lessonPart != null && (lessonPart < 1 || lessonPart > 3)) return;
    var normalizedType = trackType;
    var normalizedLessonNumber = trackLessonNumber;

    // Support old calls from previously generated screens/tests during migration.
    if (normalizedLessonNumber == null && lessonIndex != null) {
      if (lessonIndex < hanCoreLessonCount) {
        normalizedType = 'Hán';
        normalizedLessonNumber = lessonIndex + 1;
      } else {
        normalizedType = 'Nôm';
        normalizedLessonNumber = lessonIndex - hanCoreLessonCount + 1;
      }
    }

    // Keep the complete Nôm lesson/progression implementation available, but
    // do not award progress or mastery while its unnormalized dataset is paused.
    if (normalizedType == 'Nôm' && !isNomDataEnabled) return;

    if (reviewCheckpointNumber != null) {
      if (normalizedType != 'Hán' || !isHanReviewCheckpointUnlocked(reviewCheckpointNumber)) return;
    } else if (normalizedLessonNumber != null) {
      final isOpen = normalizedType == 'Nôm'
          ? isNomLessonUnlocked(normalizedLessonNumber)
          : isHanLessonUnlocked(normalizedLessonNumber);
      if (!isOpen && unlockTargetLessonNumber == null) return;
    }

    // A user cannot open a Nôm lesson without passing the matching Han checkpoint.
    if (normalizedType == 'Nôm' && normalizedLessonNumber != null &&
        completedHanReviewCheckpoints < normalizedLessonNumber) return;

    await refreshHeartRegeneration();
    xp += xpReward;
    gems += 5;
    // Chỉ thưởng tim khi hoàn tất một Node đầy đủ, không phải sau từng phần 1/3.
    if ((lessonPart == null || lessonPart >= 3) && hearts < maxHearts) hearts++;
    _normalizeHeartRegenAnchor();

    for (final character in masteredCharacters) {
      mastery[character] = ((mastery[character] ?? 0) + 1).clamp(0, 5).toInt();
    }

    if (reviewCheckpointNumber != null) {
      completedHanReviewCheckpoints = completedHanReviewCheckpoints < reviewCheckpointNumber
          ? reviewCheckpointNumber
          : completedHanReviewCheckpoints;
    } else if (normalizedLessonNumber != null) {
      if (normalizedType == 'Nôm') {
        nomLessonsCompleted = nomLessonsCompleted < normalizedLessonNumber
            ? normalizedLessonNumber
            : nomLessonsCompleted;
      } else if (lessonPart != null && normalizedLessonNumber == hanLessonsCompleted + 1) {
        // Bỏ qua callback phần cũ nếu tiến độ đã thay đổi ở màn hình khác.
        if (lessonPart == currentLessonPart) {
          // Hoàn thành phần 1/2 chỉ lưu phần kế tiếp; phần 3 mới hoàn tất Node.
          if (lessonPart < 3) {
            currentLessonPart = lessonPart + 1;
          } else {
            hanLessonsCompleted = normalizedLessonNumber;
            currentLessonPart = 1;
          }
        }
      } else {
        // Tương thích với Boss, ôn tập, học vượt và các màn hình gọi API cũ.
        if (normalizedLessonNumber > hanLessonsCompleted) {
          hanLessonsCompleted = normalizedLessonNumber;
          currentLessonPart = 1;
        }
      }
    }

    if (unlockTargetLessonNumber != null && normalizedType == 'Hán') {
      unlockedHanThroughLesson = unlockedHanThroughLesson < unlockTargetLessonNumber
          ? unlockTargetLessonNumber
          : unlockedHanThroughLesson;
      // Học vượt marks earlier Hán lessons as skipped/unlocked, but does NOT
      // auto-complete a Boss checkpoint; therefore it cannot unlock Nôm by itself.
      final beforeTarget = (unlockTargetLessonNumber - 1).clamp(0, hanCoreLessonCount).toInt();
      if (hanLessonsCompleted < beforeTarget) hanLessonsCompleted = beforeTarget;
      currentLessonPart = 1;
    }

    final activityTime = (completedAt ?? DateTime.now()).toLocal();
    final previousActivity = lastActivity ?? DateTime.tryParse(lastStudyDate ?? '');
    streak = calculateStreakAfterStudy(currentStreak: streak, lastActivity: previousActivity, now: activityTime);
    lastActivity = activityTime;
    lastStudyDate = _dateKey(activityTime);

    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('xp', xp);
      await prefs.setInt('streak', streak);
      await prefs.setInt('gems', gems);
      await prefs.setInt('hearts', hearts);
      if (lastHeartRegenTime == null) {
        await prefs.remove('lastHeartRegenTime');
      } else {
        await prefs.setString('lastHeartRegenTime', lastHeartRegenTime!.toIso8601String());
      }
      await prefs.setInt('completedLessons', completedLessons);
      await prefs.setInt('completedReviewCheckpoints', completedHanReviewCheckpoints);
      await prefs.setInt('hanLessonsCompleted', hanLessonsCompleted);
      await prefs.setInt('currentLessonPart', currentLessonPart.clamp(1, 3).toInt());
      await prefs.setString('supplementaryLanguage', supplementaryLanguage.name);
      await prefs.setBool('supplementaryLanguagePromptSeen', hasSeenSupplementaryLanguagePrompt);
      await prefs.setInt('nomLessonsCompleted', nomLessonsCompleted);
      await prefs.setInt('completedHanReviewCheckpoints', completedHanReviewCheckpoints);
      await prefs.setInt('unlockedHanThroughLesson', unlockedHanThroughLesson);
      await prefs.setInt('unlockedThroughLesson', unlockedHanThroughLesson);
      await prefs.setBool('separateTracksV1', true);
      await prefs.setBool('thematicCurriculumV3', true);
      if (lastActivity != null) {
        await prefs.setString('lastActivity', lastActivity!.toIso8601String());
        await prefs.setString('lastStudyDate', _dateKey(lastActivity!.toLocal()));
      } else if (lastStudyDate != null) {
        await prefs.setString('lastStudyDate', lastStudyDate!);
      }
      await prefs.setString('mastery', jsonEncode(mastery));
    } catch (_) {
      // Không làm gián đoạn vòng học nếu lưu trạng thái gặp lỗi tạm thời.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _heartRegenTimer?.cancel();
    super.dispose();
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
