import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:han_viet_duo/data/question.dart';
import 'package:han_viet_duo/widgets/interactive_sentence.dart';

void main() {
  testWidgets('tap on a character shows a multiline tooltip without speaker controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: InteractiveSentence(
              tokens: [
                SentenceToken(
                  text: '人',
                  hanVietReading: 'NHÂN',
                  meaning: 'người',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.triggerMode, TooltipTriggerMode.tap);
    expect(tooltip.richMessage?.toPlainText(), 'NHÂN\nngười');
    await tester.tap(find.text('人'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText &&
            widget.text.toPlainText() == 'NHÂN\nngười',
      ),
      findsOneWidget,
    );
    expect(find.byType(IconButton), findsNothing);
  });
}
