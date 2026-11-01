import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:han_viet_duo/data/models/cjk_character.dart';
import 'package:han_viet_duo/widgets/character_pronunciation_controls.dart';

Widget _host(CharacterPronunciationControls child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

const _record = CjkCharacter(
  charTraditional: '中',
  charSimplified: '中',
  charShinjitai: '中',
  meaningVi: 'ở giữa',
  readingsHanViet: ['trung'],
  readingsPinyin: ['zhōng', 'zhòng'],
  readingsOnyomi: ['チュウ', 'ジュウ', 'チュ'],
  readingsKunyomi: [],
);

void main() {
  testWidgets('Hán-Việt is always available when no supplementary language is selected',
      (tester) async {
    await tester.pumpWidget(_host(
      const CharacterPronunciationControls(
        hanVietReading: 'trung',
        supplementaryLanguage: SupplementaryLanguage.none,
        cjkCharacter: _record,
      ),
    ));

    expect(find.byType(IconButton), findsOneWidget);
    expect(find.byTooltip('Nghe âm Hán-Việt: trung'), findsOneWidget);
  });

  testWidgets('Mandarin adds one supplementary pronunciation button', (tester) async {
    await tester.pumpWidget(_host(
      const CharacterPronunciationControls(
        hanVietReading: 'trung',
        supplementaryLanguage: SupplementaryLanguage.mandarin,
        cjkCharacter: _record,
      ),
    ));

    expect(find.byType(IconButton), findsNWidgets(2));
    expect(find.byTooltip('Nghe âm Hán-Việt: trung'), findsOneWidget);
    expect(find.byTooltip('Nghe Quan thoại · zhōng'), findsOneWidget);
  });

  testWidgets('Japanese exposes at most two On-yomi buttons, using Kana readings',
      (tester) async {
    await tester.pumpWidget(_host(
      const CharacterPronunciationControls(
        hanVietReading: 'trung',
        supplementaryLanguage: SupplementaryLanguage.japanese,
        cjkCharacter: _record,
      ),
    ));

    // One primary Hán-Việt button plus at most two Japanese reading buttons.
    expect(find.byType(IconButton), findsNWidgets(3));
    expect(find.byTooltip('Nghe Hán-Nhật · On’yomi チュウ'), findsOneWidget);
    expect(find.byTooltip('Nghe Hán-Nhật · On’yomi ジュウ'), findsOneWidget);
    expect(find.byTooltip('Nghe Hán-Nhật · On’yomi チュ'), findsNothing);
  });
}
