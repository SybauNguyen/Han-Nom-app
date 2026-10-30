import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:han_viet_duo/data/han_seed_data.dart';
import 'package:han_viet_duo/data/legacy_nom_codepoints.dart';
import 'package:han_viet_duo/data/dictionary_search.dart';
import 'package:han_viet_duo/data/question.dart';
import 'package:han_viet_duo/state/app_state.dart';

void main() {
  test('moi bai giu bo cau hoi co ban va them noi cap/xep nghia tuong tac', () {
    for (var index = 0; index < hanLessonUnits.length; index++) {
      final characters = charactersForUnit(index);
      final questions = generateQuestions(characters);
      final curatedTranslationCount = generateCuratedTranslationQuestions(
        characters,
        knownCharacters: characters,
        sectionTitle: 'test',
        random: Random(21),
      ).length;
      final expected = characters.length * 4 +
          (characters.any((c) => c.character == '學') ? 1 : 0) +
          (characters.length >= 2 ? 1 : 0) +
          curatedTranslationCount;
      expect(characters.length, 10, reason: hanLessonUnits[index].title);
      expect(questions, hasLength(expected));
      expect(questions.where((q) => q.type == QuestionType.radical), hasLength(characters.length));
      expect(questions.where((q) => q.type == QuestionType.reading), hasLength(characters.length));
      expect(questions.where((q) => q.type == QuestionType.character), hasLength(characters.length));
      expect(questions.where((q) => q.type == QuestionType.typing), hasLength(characters.length));
      expect(questions.where((q) => q.type == QuestionType.translateSentence).length,
          questions.where((q) => q.type == QuestionType.translateHanVietToCharacter).length);
    }
  });


  test('du lieu Nom cu da duoc go bo nhung khung lo trinh van duoc giu', () {
    expect(isNomDataEnabled, isFalse);
    expect(retiredNomCodepoints.every((symbol) => findCharacter(symbol) == null), isTrue);
    expect(seedCharacters, hasLength(250));
    expect(seedCharacters.every((character) => character.isHan), isTrue);
    expect(nomLessonUnits, hasLength(3));
    expect(nomLessonUnits.every((unit) => unit.isNom && unit.characters.isEmpty), isTrue);
  });

  test('ma Unicode Nom cu chi con trong danh sach don dep, khong con seed nghia', () {
    expect(retiredNomCodepoints, hasLength(29));
    expect(retiredNomCodepoints.every((symbol) => findCharacter(symbol) == null), isTrue);
    expect(seedCharacters.map((c) => c.character).toSet().intersection(retiredNomCodepoints), isEmpty);
  });

  test('don du lieu Nom cu khong lam mat tien do Han hoac tai nguyen', () async {
    final oldNomCharacter = retiredNomCodepoints.first;
    SharedPreferences.setMockInitialValues({
      'separateTracksV1': true,
      'thematicCurriculumV3': true,
      'heartShopMigrationV2': true,
      'hanLessonsCompleted': 4,
      'nomLessonsCompleted': 2,
      'completedHanReviewCheckpoints': 0,
      'xp': 125,
      'gems': 340,
      'hearts': 4,
      'mastery': jsonEncode({oldNomCharacter: 4, '一': 3, '未': 2}),
    });
    final appState = AppState();
    await appState.load();
    expect(appState.hanLessonsCompleted, 4);
    expect(appState.nomLessonsCompleted, 0);
    expect(appState.xp, 125);
    expect(appState.gems, 340);
    expect(appState.hearts, 4);
    expect(appState.masteryOf(oldNomCharacter), 0);
    expect(appState.masteryOf('一'), 3);
    expect(appState.masteryOf('未'), 2, reason: 'Giữ mastery chữ khác dù chưa có trong seed lõi');
    appState.dispose();
  });

  test('cau trac nghiem co 4 lua chon duy nhat va chua dap an', () {
    for (var index = 0; index < hanLessonUnits.length; index++) {
      for (final question in generateQuestions(charactersForUnit(index))) {
        if (question.type == QuestionType.typing) {
          expect(question.options, isEmpty);
          expect(question.acceptedAnswers, isNotEmpty);
        } else if (question.type == QuestionType.matchingPairs) {
          expect(question.matchingPairs, isNotNull);
          expect(question.matchingPairs!.length, greaterThanOrEqualTo(2));
          expect(question.matchingPairs!.length, lessThanOrEqualTo(4));
        } else if (question.type == QuestionType.translateSentence) {
          expect(question.sentenceTokens, isNotEmpty);
          expect(question.options, hasLength(question.sentenceTokens!.length));
          expect(question.correctAnswer, question.options.join(' '));
        } else if (question.type == QuestionType.translateHanVietToCharacter) {
          expect(question.sourceText, isNotEmpty);
          expect(question.sentenceTokens, isNotEmpty);
          expect(question.options, hasLength(question.sentenceTokens!.length));
          expect(question.correctAnswer, question.options.join(' '));
        } else {
          expect(question.options, hasLength(4), reason: question.prompt);
          expect(question.options.toSet(), hasLength(4), reason: question.prompt);
          expect(question.options, contains(question.correctAnswer), reason: question.prompt);
        }
      }
    }
  });

  test('bo seed hoat dong chi gom 250 chu Han duy nhat va khong con muc Nom cu', () {
    expect(seedCharacters, hasLength(250));
    expect(seedCharacters.map((c) => c.character).toSet(), hasLength(250));
    expect(seedCharacters.where((c) => c.isHan), hasLength(250));
    expect(seedCharacters.where((c) => c.isNom), isEmpty);
    expect(findCharacter('一')?.hanVietReading, 'nhất');
    expect(findCharacter('忠')?.hanVietReading, 'trung');
    expect(findCharacter('中')?.hanVietReading, 'trung');
    expect(findCharacter('犬')?.hanVietReading, 'khuyển');
    expect(findCharacter('青')?.meaning, 'màu xanh');
    expect(findCharacter('看')?.hanVietReading, 'khán');
    expect(findCharacter('年')?.hanVietReading, 'niên');
    expect(findCharacter('米')?.meaning, 'gạo');
    expect(lessonUnits, hasLength(28));
    expect(lessonUnits.take(hanCoreLessonCount).every((unit) => !unit.isNom), isTrue);
    expect(lessonUnits.skip(hanCoreLessonCount).every((unit) => unit.isNom), isTrue);
    for (final unit in hanLessonUnits) {
      expect(unit.characters.length, 10, reason: unit.title);
      for (final symbol in unit.characters) {
        expect(findCharacter(symbol), isNotNull, reason: 'Missing Hán seed for $symbol');
      }
    }
    expect(nomLessonUnits.every((unit) => unit.characters.isEmpty), isTrue);
  });


  test('lo trinh 25 bai Han x 10 chu, 5 Tong On tap va Nôm tam an', () {
    expect(hanLessonUnits, hasLength(25));
    expect(nomLessonUnits, hasLength(3));
    expect(hanLessonsPerCycle, 5);
    expect(hanCoreLessonCount ~/ hanLessonsPerCycle, 5);
    expect(hanLessonUnits.every((unit) => unit.characters.length == 10), isTrue);
    expect(hanLessonUnits.expand((unit) => unit.characters).toSet(), hasLength(250));
    expect(nomLessonUnits.every((unit) => unit.characters.isEmpty), isTrue);
    expect(hanLessonUnits.first.characters, ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十']);
  });

  test('typed answers accept both Han-Viet reading and meaning', () {
    final questions = generateQuestions(charactersForUnit(0));
    final typed = questions.where((q) => q.type == QuestionType.typing).first;
    expect(typed.acceptedAnswers, contains(typed.correctAnswer.toLowerCase()));
    expect(typed.acceptedAnswers, contains(findCharacter(typed.character)!.meaning.toLowerCase()));
  });
  test('hoc vuot lay 10 chu duy nhat chi tu cac bai truoc va dung format Phan 3', () {
    final characters = randomJumpAheadCharacters(
      limit: 10,
      targetLessonNumber: 3,
      random: Random(7),
    );
    expect(characters, hasLength(10));
    expect(characters.map((c) => c.character).toSet(), hasLength(10));

    final earlierSymbols = hanLessonUnits.take(2).expand((unit) => unit.characters).toSet();
    expect(characters.every((c) => earlierSymbols.contains(c.character)), isTrue);

    final translationPair = generateCuratedTranslationQuestions(
      characters,
      knownCharacters: characters,
      sectionTitle: 'test',
      random: Random(8),
    );
    final questions = generateLessonPartQuestions(characters, part: 3, random: Random(8));
    expect(questions, hasLength(23 + translationPair.length));
    expect(questions.any((q) => q.type == QuestionType.matchingPairs), isTrue);
    expect(questions.where((q) => q.type == QuestionType.translateSentence).length,
        questions.where((q) => q.type == QuestionType.translateHanVietToCharacter).length);
    expect(questions.where((q) => q.type == QuestionType.typing), hasLength(10));
    expect(randomJumpAheadCharacters(limit: 10, targetLessonNumber: 1), isEmpty);
    expect(randomJumpAheadCharacters(limit: 10, targetLessonNumber: hanCoreLessonCount + 1), isEmpty);

    // Legacy API flags must also use the current Part 3 engine.
    final legacyJumpCall = generateQuestions(characters, jumpAheadMode: true);
    expect(legacyJumpCall, hasLength(23 + translationPair.length));
    expect(legacyJumpCall.where((q) => q.type == QuestionType.typing), hasLength(10));
  });
  test('hoc vuot bai 2 lay du 10 chu ngau nhien trong bai 1, khong lay chu tuong lai', () {
    final characters = randomJumpAheadCharacters(
      limit: 10,
      targetLessonNumber: 2,
      random: Random(3),
    );
    expect(characters, hasLength(10));
    expect(characters.map((c) => c.character).toSet(), hasLength(10));
    expect(characters.map((c) => c.character).toSet(),
        hanLessonUnits.first.characters.toSet());
  });

  test('hoan thanh hoc vuot thuong 50 XP va mo khoa dung bai muc tieu', () async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.load();

    await appState.finishLesson(
      lessonIndex: null,
      masteredCharacters: {'一', '人'},
      xpReward: 50,
      unlockTargetLessonNumber: 3,
    );

    expect(appState.xp, 50);
    expect(appState.completedLessons, 2);
    expect(appState.completedLessons < 3, isTrue);
    expect(appState.gems, 505);
    appState.dispose();
  });

  test('streak uses calendar days: today holds, yesterday increments, a longer gap resets', () {
    final now = DateTime(2026, 10, 10, 20, 30);
    expect(
      calculateStreakAfterStudy(
        currentStreak: 5,
        lastActivity: DateTime(2026, 10, 10, 7, 15),
        now: now,
      ),
      5,
    );
    expect(
      calculateStreakAfterStudy(
        currentStreak: 5,
        lastActivity: DateTime(2026, 10, 9, 23, 59),
        now: now,
      ),
      6,
    );
    expect(
      calculateStreakAfterStudy(
        currentStreak: 5,
        lastActivity: DateTime(2026, 10, 8, 23, 59),
        now: now,
      ),
      1,
    );
    expect(
      calculateStreakAfterStudy(currentStreak: 0, lastActivity: null, now: now),
      1,
    );
  });

  test('legacy lastStudyDate is migrated and stale streak restarts at one after studying', () async {
    final now = DateTime.now();
    final twoDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
    final legacyDate = '${twoDaysAgo.year.toString().padLeft(4, '0')}-'
        '${twoDaysAgo.month.toString().padLeft(2, '0')}-'
        '${twoDaysAgo.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'xp': 120,
      'streak': 7,
      'gems': 300,
      'heartShopMigrationV2': true,
      'lastStudyDate': legacyDate,
    });
    final appState = AppState();
    await appState.load();
    expect(appState.streak, 0);
    expect(appState.lastActivity, isNotNull);

    await appState.finishLesson(
      lessonIndex: null,
      masteredCharacters: const {},
      completedAt: now,
    );
    expect(appState.streak, 1);
    expect(appState.lastActivity?.year, now.year);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lastActivity'), isNotNull);
    appState.dispose();
  });

  test('bai on chi tao dich khi tim duoc phrase da duyet va dung ca hai chieu', () {
    final lessonCharacters = charactersForUnit(0);
    final lessonQuestions = generateLessonPartQuestions(lessonCharacters, part: 3, random: Random(1));
    expect(lessonQuestions.where((q) => q.type == QuestionType.matchingPairs), hasLength(1));
    expect(lessonQuestions.where((q) => q.type == QuestionType.translateSentence), isEmpty,
        reason: 'Bài số đếm không được ghép nghĩa từng chữ thành câu giả.');
    expect(lessonQuestions.where((q) => q.type == QuestionType.translateHanVietToCharacter), isEmpty);

    final checkpointCharacters = randomReviewCheckpointCharacters(checkpointNumber: 1, random: Random(1));
    final checkpointKnown = hanLessonUnits.take(hanLessonsPerCycle)
        .expand((unit) => unit.characters).map(findCharacter).whereType<HanCharacter>().toList();
    expect(checkpointCharacters, hasLength(20));
    final expectedPair = generateCuratedTranslationQuestions(
      checkpointCharacters,
      knownCharacters: checkpointKnown,
      sectionTitle: 'test',
      random: Random(2),
    );
    final reviewQuestions = generateLessonPartQuestions(
      checkpointCharacters,
      part: 3,
      knownCharacters: checkpointKnown,
      random: Random(2),
    );
    expect(reviewQuestions, hasLength(43 + expectedPair.length));
    expect(reviewQuestions.any((q) => q.type == QuestionType.matchingPairs), isTrue);
    expect(reviewQuestions.where((q) => q.type == QuestionType.typing), hasLength(20));
    expect(reviewQuestions.where((q) => q.type == QuestionType.translateSentence).length,
        reviewQuestions.where((q) => q.type == QuestionType.translateHanVietToCharacter).length);
  });

  test('cum 朋友 duoc doc la bang huu va co bai dich nguoc ghep chu Han', () {
    final friends = [findCharacter('朋')!, findCharacter('友')!];
    final questions = generateCuratedTranslationQuestions(
      friends,
      knownCharacters: friends,
      sectionTitle: 'test',
      random: Random(3),
    );
    expect(questions, hasLength(2));
    final forward = questions.singleWhere((q) => q.type == QuestionType.translateSentence);
    expect(forward.correctAnswer, 'bằng hữu');
    expect(forward.options, ['bằng', 'hữu']);
    expect(forward.sentenceTokens!.map((token) => token.text).join(), '朋友');
    expect(forward.correctAnswer, isNot(contains('bạn bè bạn')));

    final reverse = questions.singleWhere((q) => q.type == QuestionType.translateHanVietToCharacter);
    expect(reverse.sourceText, 'Bằng hữu');
    expect(reverse.options, ['朋', '友']);
    expect(reverse.correctAnswer, '朋 友');
  });

  test('khong tao cau dich neu mot ky tu cua phrase chua duoc hoc', () {
    final partialKnown = [findCharacter('南')!, findCharacter('國')!, findCharacter('山')!];
    final questions = generateCuratedTranslationQuestions(
      partialKnown,
      knownCharacters: partialKnown,
      sectionTitle: 'test',
      random: Random(4),
    );
    expect(questions, isEmpty);
  });

  test('phrase uu tien cau dai va moi ky tu deu co trong seed', () {
    final seedSymbols = seedCharacters.map((character) => character.character).toSet();
    expect(curatedHanVietPhrases, isNotEmpty);
    for (final phrase in curatedHanVietPhrases) {
      expect(phrase.symbols.every(seedSymbols.contains), isTrue, reason: phrase.hanText);
      expect(phrase.symbols.length, greaterThanOrEqualTo(2));
    }
    final emotionUnit = charactersForUnit(16);
    final questions = generateCuratedTranslationQuestions(
      emotionUnit,
      knownCharacters: seedCharacters,
      sectionTitle: 'test',
      random: Random(5),
    );
    expect(questions, hasLength(2));
    final forward = questions.singleWhere((question) => question.type == QuestionType.translateSentence);
    final reverse = questions.singleWhere((question) => question.type == QuestionType.translateHanVietToCharacter);
    expect(forward.correctAnswer.split(' '), hasLength(greaterThanOrEqualTo(4)),
        reason: 'Ưu tiên phrase dài/câu đủ ký tự thay vì ghép nghĩa từng chữ');
    expect(reverse.correctAnswer, forward.sentenceTokens!.map((token) => token.text).join(' '));
    expect(forward.sentenceTokens!.length, greaterThanOrEqualTo(4));
  });

  test('ngan hang dich co cum dai hop le va moi chu deu nam trong seed', () {
    final knownSymbols = seedCharacters.map((character) => character.character).toSet();
    final longPhrases = <String>{
      '大江東去', '四海一家', '五湖四海', '江河湖海', '山河大地', '一日千秋', '白日青天',
    };
    expect(curatedHanVietPhrases.map((phrase) => phrase.hanText).toSet(), containsAll(longPhrases));
    for (final phrase in curatedHanVietPhrases) {
      expect(phrase.symbols.every(knownSymbols.contains), isTrue, reason: phrase.hanText);
    }

    final riverCharacters = ['大', '江', '東', '去'].map(findCharacter).whereType<HanCharacter>().toList();
    final questions = generateCuratedTranslationQuestions(
      riverCharacters,
      knownCharacters: riverCharacters,
      sectionTitle: 'test',
      random: Random(2),
    );
    expect(questions, hasLength(2));
    expect(questions.first.correctAnswer, 'đại giang đông khứ');
    expect(questions.last.correctAnswer, '大 江 東 去');
  });

  test('dictionary search supports accentless Vietnamese and searches radicals', () {
    final accentless = searchHanCharacters(seedCharacters, 'khuyen');
    expect(accentless.any((c) => c.character == '犬'), isTrue);

    final radicalMatches = searchHanCharacters(seedCharacters, '心');
    expect(radicalMatches, isNotEmpty);
    expect(radicalMatches.any((c) => c.radical == '心'), isTrue);

    final meaningSearch = searchHanCharacters(seedCharacters, 'nguoi');
    expect(meaningSearch.any((c) => c.character == '人'), isTrue);
  });

  test('Tong On tap lay 20 chu Han duy nhat ngau nhien trong 50 chu cua 5 bai truoc', () {
    for (var checkpoint = 1; checkpoint <= hanCoreLessonCount ~/ hanLessonsPerCycle; checkpoint++) {
      final selected = randomReviewCheckpointCharacters(checkpointNumber: checkpoint, random: Random(checkpoint));
      final prior = hanLessonUnits.skip((checkpoint - 1) * hanLessonsPerCycle).take(hanLessonsPerCycle).expand((u) => u.characters).toSet();
      expect(selected, hasLength(20));
      expect(selected.map((c) => c.character).toSet(), hasLength(20));
      expect(selected.every((c) => prior.contains(c.character)), isTrue);
      expect(selected.every((c) => c.isHan), isTrue);
      final knownCharacters = hanLessonUnits.skip((checkpoint - 1) * hanLessonsPerCycle)
          .take(hanLessonsPerCycle).expand((unit) => unit.characters)
          .map(findCharacter).whereType<HanCharacter>().toList();
      final expectedTranslations = generateCuratedTranslationQuestions(
        selected,
        knownCharacters: knownCharacters,
        sectionTitle: 'test',
        random: Random(checkpoint + 10),
      ).length;
      final questions = generateLessonPartQuestions(
        selected,
        part: 3,
        knownCharacters: knownCharacters,
        random: Random(checkpoint + 10),
      );
      expect(questions, hasLength(43 + expectedTranslations));
      expect(questions.where((q) => q.type == QuestionType.typing), hasLength(20));
      expect(questions.any((q) => q.type == QuestionType.matchingPairs), isTrue);
      expect(questions.where((q) => q.type == QuestionType.translateSentence).length,
          questions.where((q) => q.type == QuestionType.translateHanVietToCharacter).length);
      final legacyReviewCall = generateQuestions(
        selected,
        reviewCheckpointMode: true,
        knownCharacters: knownCharacters,
        random: Random(checkpoint + 10),
      );
      expect(legacyReviewCall, hasLength(43 + expectedTranslations));
      expect(legacyReviewCall.where((q) => q.type == QuestionType.typing), hasLength(20));
    }
  });
  test('mnemonics are carried into questions and detail records', () {
    final rest = findCharacter('休')!;
    expect(rest.mnemonic, contains('nghỉ ngơi'));
    final questions = generateQuestions([rest]);
    expect(questions.where((q) => q.character == '休').every((q) => q.mnemonic == rest.mnemonic), isTrue);
    expect(findCharacter('森')?.mnemonic, contains('rừng rậm'));
    expect(findCharacter('淚')?.mnemonic, contains('nước mắt'));
    expect(findCharacter('休')?.isHan, isTrue);
  });

  test('roadmap unlocks Boss after five Han lessons and lesson six after the Boss', () async {
    SharedPreferences.setMockInitialValues({
      'separateTracksV1': true,
      'thematicCurriculumV3': true,
      'hanLessonsCompleted': 5,
      'nomLessonsCompleted': 0,
      'completedHanReviewCheckpoints': 0,
    });
    final appState = AppState();
    await appState.load();
    expect(appState.isHanReviewCheckpointUnlocked(1), isTrue);
    expect(appState.isHanLessonUnlocked(6), isFalse);
    expect(appState.isNomLessonUnlocked(1), isFalse);

    await appState.finishLesson(
      lessonIndex: null,
      trackType: 'Hán',
      masteredCharacters: const {},
      reviewCheckpointNumber: 1,
      completedAt: DateTime(2026, 10, 11, 10),
    );
    expect(appState.completedHanReviewCheckpoints, 1);
    expect(appState.isHanLessonUnlocked(6), isTrue);
    expect(appState.isNomLessonUnlocked(1), isTrue);
    expect(appState.isNomLessonUnlocked(2), isFalse);
    appState.dispose();
  });

  test('logic lo trinh Nom van giu nhung khong ghi tien do khi bo du lieu dang tam an', () async {
    SharedPreferences.setMockInitialValues({
      'separateTracksV1': true,
      'thematicCurriculumV3': true,
      'hanLessonsCompleted': 5,
      'nomLessonsCompleted': 0,
      'completedHanReviewCheckpoints': 0,
    });
    final appState = AppState();
    await appState.load();
    expect(appState.isNomLessonUnlocked(1), isFalse);

    // Finishing Hán lesson five opens the Boss, not the Nôm lesson by itself.
    expect(appState.isHanReviewCheckpointUnlocked(1), isTrue);
    await appState.finishLesson(
      lessonIndex: null,
      trackType: 'Hán',
      masteredCharacters: const {},
      reviewCheckpointNumber: 1,
    );
    expect(appState.isNomLessonUnlocked(1), isTrue);
    expect(appState.isNomLessonUnlocked(2), isFalse);

    await appState.finishLesson(
      lessonIndex: null,
      trackType: 'Nôm',
      trackLessonNumber: 1,
      masteredCharacters: retiredNomCodepoints.take(1).toSet(),
    );
    expect(appState.nomLessonsCompleted, 0, reason: 'Không ghi tiến độ khi dữ liệu Nôm đang tạm ẩn');
    expect(appState.isNomLessonUnlocked(2), isFalse);
    appState.dispose();
  });

  test('bo sinh cau hoi va khung Nôm van ton tai khi du lieu Nôm dang tat', () {
    final han = findCharacter('中')!;
    final questions = generateQuestions([han]);
    expect(questions.every((q) => q.characterType == 'Hán'), isTrue);
    expect(questions.any((q) => q.type == QuestionType.typing), isTrue);
    expect(nomLessonUnits, hasLength(3));
    expect(nomLessonUnits.every((unit) => unit.isNom), isTrue);
    expect(retiredNomCodepoints.every((symbol) => findCharacter(symbol) == null), isTrue);
  });

  test('tiến độ hồ sơ phân biệt Hán đã học và Nôm đã giải mã', () async {
    SharedPreferences.setMockInitialValues({'completedLessons': 50, 'checkpointSystemV1': true});
    final appState = AppState();
    await appState.load();
    await appState.finishLesson(lessonIndex: 0, masteredCharacters: {'一', '人'});
    await appState.finishLesson(lessonIndex: hanCoreLessonCount, masteredCharacters: retiredNomCodepoints.take(1).toSet());
    expect(appState.masteryOf('一'), 1);
    expect(appState.masteryOf('人'), 1);
    expect(retiredNomCodepoints.every((symbol) => appState.masteryOf(symbol) == 0), isTrue, reason: 'Tiến độ thuộc dữ liệu Nôm đã gỡ không được giữ lại');
    appState.dispose();
  });


  test('tat ca 250 chu seed deu thuoc dung mot Node Han; cac Node Nom de trong', () {
    final roadmapSymbols = hanLessonUnits.expand((unit) => unit.characters).toList();
    expect(roadmapSymbols, hasLength(250));
    expect(roadmapSymbols.toSet(), hasLength(250));
    expect(roadmapSymbols.toSet(), containsAll(seedCharacters.map((c) => c.character)));
    expect(nomLessonUnits.every((unit) => unit.characters.isEmpty), isTrue);
    expect(charactersForUnit(hanCoreLessonCount), isEmpty);
  });


  test('migration roadmap cu gop chung 50 bai Han va 6 bai Nom sang cau truc 25/3', () async {
    SharedPreferences.setMockInitialValues({
      'completedLessons': 55,
      'completedReviewCheckpoints': 4,
      'unlockedThroughLesson': 22,
      'currentLessonPart': 3,
    });
    final appState = AppState();
    await appState.load();
    expect(appState.hanLessonsCompleted, 25);
    expect(appState.nomLessonsCompleted, 0, reason: 'Du lieu Nom cu da duoc go bo');
    expect(appState.completedHanReviewCheckpoints, 2);
    expect(appState.unlockedHanThroughLesson, 25);
    expect(appState.currentLessonPart, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('thematicCurriculumV3'), isTrue);
    appState.dispose();
  });

  test('migration chuyen tien do tu 50 bai x 5 chu sang 25 bai x 10 chu', () async {
    SharedPreferences.setMockInitialValues({
      'separateTracksV1': true,
      'hanLessonsCompleted': 20,
      'nomLessonsCompleted': 4,
      'completedHanReviewCheckpoints': 4,
      'unlockedHanThroughLesson': 22,
      'currentLessonPart': 3,
    });
    final appState = AppState();
    await appState.load();
    expect(appState.hanLessonsCompleted, 10);
    expect(appState.nomLessonsCompleted, 0, reason: 'Du lieu Nom cu da duoc go bo');
    expect(appState.completedHanReviewCheckpoints, 2);
    expect(appState.unlockedHanThroughLesson, 11);
    expect(appState.currentLessonPart, 1, reason: 'Node va chu de da doi nen phan dang hoc duoc mo lai tu dau');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('thematicCurriculumV3'), isTrue);
    appState.dispose();
  });

  test('tim tu hoi mot moi 30 phut va giu lai phan thoi gian du khi app mo lai', () async {
    final now = DateTime.now();
    final anchor = now.subtract(const Duration(minutes: 35));
    SharedPreferences.setMockInitialValues({
      'separateTracksV1': true,
      'hearts': 1,
      'lastHeartRegenTime': anchor.toIso8601String(),
    });
    final appState = AppState();
    await appState.load();
    expect(appState.hearts, 2);
    expect(appState.lastHeartRegenTime, anchor.add(const Duration(minutes: 30)));
    expect(appState.heartRegenSecondsRemaining, greaterThan(0));
    expect(appState.heartRegenSecondsRemaining, lessThanOrEqualTo(25 * 60));
    appState.dispose();
  });

  test('tim hoi offline toi da 5 va xoa moc dem nguoc khi day', () async {
    SharedPreferences.setMockInitialValues({
      'separateTracksV1': true,
      'hearts': 2,
      'lastHeartRegenTime': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    });
    final appState = AppState();
    await appState.load();
    expect(appState.hearts, 5);
    expect(appState.lastHeartRegenTime, isNull);
    expect(appState.heartRegenSecondsRemaining, isNull);
    appState.dispose();
  });

  test('tru tim tu day bat dau moc 30 phut; them tim den day xoa moc', () async {
    SharedPreferences.setMockInitialValues({'separateTracksV1': true, 'hearts': 5});
    final appState = AppState();
    await appState.load();
    await appState.recordWrongAnswer();
    expect(appState.hearts, 4);
    expect(appState.lastHeartRegenTime, isNotNull);
    expect(appState.heartRegenSecondsRemaining, greaterThan(0));
    await appState.addHeart(1);
    expect(appState.hearts, 5);
    expect(appState.lastHeartRegenTime, isNull);
    appState.dispose();
  });


  test('moi Node Han chia thanh 3 phan va phan 3 co bai go am', () {
    final characters = charactersForUnit(0);
    final part1 = generateLessonPartQuestions(characters, part: 1, random: Random(7));
    final part2 = generateLessonPartQuestions(characters, part: 2, random: Random(7));
    final part3 = generateLessonPartQuestions(characters, part: 3, random: Random(7));

    expect(part1.where((q) => q.type == QuestionType.introduceWord), hasLength(5));
    expect(part1.where((q) => q.type == QuestionType.introduceWord).map((q) => q.character).toSet(), {'一', '二', '三', '四', '五'});
    expect(part2.where((q) => q.type == QuestionType.introduceWord), hasLength(5));
    expect(part2.where((q) => q.type == QuestionType.introduceWord).map((q) => q.character).toSet(), {'六', '七', '八', '九', '十'});
    expect(part1.where((q) => q.type == QuestionType.typing), isEmpty);
    expect(part2.where((q) => q.type == QuestionType.typing), isEmpty);
    expect(part3.where((q) => q.type == QuestionType.typing), hasLength(10));
    expect(part3.where((q) => q.type == QuestionType.introduceWord), isEmpty);
    for (final question in [...part1, ...part2, ...part3]) {
      if (question.type == QuestionType.matchingPairs) {
        expect(question.matchingPairs!.length, inInclusiveRange(2, 4));
      } else if (question.type == QuestionType.translateSentence) {
        expect(question.options, hasLength(question.sentenceTokens!.length));
        expect(question.correctAnswer, question.options.join(' '));
      } else if (question.type == QuestionType.translateHanVietToCharacter) {
        expect(question.sourceText, isNotEmpty);
        expect(question.options, hasLength(question.sentenceTokens!.length));
        expect(question.correctAnswer, question.options.join(' '));
      } else if (question.type == QuestionType.typing) {
        expect(question.acceptedAnswers, contains(question.correctAnswer.toLowerCase()));
      } else {
        expect(question.options, hasLength(4), reason: question.prompt);
        expect(question.options, contains(question.correctAnswer), reason: question.prompt);
      }
    }
  });

  test('tien do phan hoc duoc luu va chi hoan tat Node sau phan 3', () async {
    SharedPreferences.setMockInitialValues({'separateTracksV1': true});
    var appState = AppState();
    await appState.load();
    expect(appState.currentLessonPart, 1);

    await appState.finishLesson(
      lessonIndex: null,
      trackType: 'Hán',
      trackLessonNumber: 1,
      lessonPart: 1,
      masteredCharacters: {'一'},
      xpReward: 15,
    );
    expect(appState.hanLessonsCompleted, 0);
    expect(appState.currentLessonPart, 2);
    appState.dispose();

    appState = AppState();
    await appState.load();
    expect(appState.currentLessonPart, 2, reason: 'Phần học phải được khôi phục sau khi mở app');
    await appState.finishLesson(
      lessonIndex: null,
      trackType: 'Hán',
      trackLessonNumber: 1,
      lessonPart: 2,
      masteredCharacters: {'三'},
      xpReward: 15,
    );
    expect(appState.hanLessonsCompleted, 0);
    expect(appState.currentLessonPart, 3);
    await appState.finishLesson(
      lessonIndex: null,
      trackType: 'Hán',
      trackLessonNumber: 1,
      lessonPart: 3,
      masteredCharacters: {'一', '二', '三'},
      xpReward: 15,
    );
    expect(appState.hanLessonsCompleted, 1);
    expect(appState.currentLessonPart, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('currentLessonPart'), 1);
    expect(prefs.getInt('hanLessonsCompleted'), 1);
    appState.dispose();
  });



  test('Phan 3 giam lap lai: moi chu co mot cau go am va chi mot nhan dien co ban', () {
    final characters = charactersForUnit(4);
    final questions = generateLessonPartQuestions(characters, part: 3, random: Random(29));
    final typed = questions.where((q) => q.type == QuestionType.typing).toList();
    final readings = questions.where((q) => q.type == QuestionType.reading).length;
    final meanings = questions.where((q) => q.type == QuestionType.character).length;
    expect(typed, hasLength(10));
    expect(typed.map((q) => q.associatedCharacter).toSet(), hasLength(10));
    expect(readings + meanings, 12, reason: '10 câu nhận diện cơ bản + 2 câu kiểm tra chéo ngẫu nhiên');
    expect(readings, inInclusiveRange(5, 7));
    expect(meanings, inInclusiveRange(5, 7));
  });

  test('Tong On tap va Hoc vuot tang bai go am Han-Viet cau van va khong lap cau trong mot luot', () {
    final symbols = '日出東方人多地少魚游水中父母愛子江河入海春來花開朋友來家讀書問答'.split('');
    final characters = symbols.map(findCharacter).whereType<HanCharacter>().toList();
    expect(characters.length, symbols.length);

    final daily = generateAdvancedReviewQuestions(
      characters: characters,
      knownCharacters: seedCharacters,
      mode: ReviewChallengeMode.dailyReview,
      random: Random(91),
    );
    final checkpoint = generateAdvancedReviewQuestions(
      characters: characters,
      knownCharacters: seedCharacters,
      mode: ReviewChallengeMode.checkpoint,
      random: Random(92),
    );
    final jumpAhead = generateAdvancedReviewQuestions(
      characters: characters,
      knownCharacters: seedCharacters,
      mode: ReviewChallengeMode.jumpAhead,
      random: Random(93),
    );

    List<Question> sentenceTasks(List<Question> questions) =>
        questions.where((q) => q.type == QuestionType.typingSentenceReading).toList();
    final dailySentences = sentenceTasks(daily);
    final checkpointSentences = sentenceTasks(checkpoint);
    final jumpSentences = sentenceTasks(jumpAhead);
    expect(dailySentences.length, 4);
    expect(checkpointSentences.length, 9);
    expect(jumpSentences.length, 16);
    expect(checkpointSentences.length, greaterThan(dailySentences.length));
    expect(jumpSentences.length, greaterThan(checkpointSentences.length));

    for (final taskSet in [dailySentences, checkpointSentences, jumpSentences]) {
      expect(taskSet.map((q) => q.sourceText).toSet().length, taskSet.length,
          reason: 'Không được lặp cùng một câu Hán văn trong một lượt');
      for (final question in taskSet) {
        expect(question.sourceText, isNotEmpty);
        expect(question.correctAnswer, isNotEmpty);
        expect(question.options, isEmpty, reason: 'Bài gõ âm Hán-Việt không được đoán bằng trắc nghiệm');
        expect(question.acceptedAnswers, contains(question.correctAnswer));
        expect(question.meaningExplanation, isNotEmpty,
            reason: 'Nghĩa tiếng Việt chỉ dùng làm chú thích sau khi nộp câu trả lời');
      }
    }
  });

  test('長江入海 is answered with Hán-Việt reading and only then explains Vietnamese meaning', () {
    final target = ['長', '江', '入', '海'].map(findCharacter).whereType<HanCharacter>().toList();
    expect(target.length, 4);
    final questions = generateSentenceReadingTypingQuestions(
      targetCharacters: target,
      knownCharacters: seedCharacters,
      limit: 100,
      sectionTitle: 'Kiểm thử câu',
      random: Random(2026),
    );
    final question = questions.firstWhere((item) => item.sourceText == '長江入海');

    expect(question.type, QuestionType.typingSentenceReading);
    expect(question.correctAnswer, 'trường giang nhập hải');
    expect(question.acceptedAnswers, contains('trường giang nhập hải'));
    expect(question.meaningExplanation, 'Trường Giang đổ ra biển');
    expect(question.options, isEmpty);
  });

  test('toan bo cau van de kiem duoc chi dung chu trong curriculum 250 chu', () {
    final known = seedCharacters.map((character) => character.character).toSet();
    for (final phrase in curatedHanVietPhrases) {
      expect(phrase.symbols.every(known.contains), isTrue,
          reason: 'Phrase ${phrase.hanText} dùng chữ chưa thuộc curriculum');
    }
  });

}
