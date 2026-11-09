import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/widgets/session_celebration.dart';

import 'fake_game_feedback.dart';

void main() {
  Future<int> pump(
    WidgetTester tester, {
    required FakeGameFeedback feedback,
    bool big = true,
    bool reduceMotion = false,
    ValueNotifier<int>? rebuild,
  }) async {
    var taps = 0;
    await tester.pumpWidget(feedback.provide(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: SessionCelebration(
            big: big,
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: rebuild ?? ValueNotifier(0),
                builder: (context, n, child) => ElevatedButton(
                  onPressed: () => taps++,
                  child: Text('Next batch $n'),
                ),
              ),
            ),
          ),
        ),
      ),
    )));
    await tester.pump(); // post-frame: feedback + confetti start
    return taps;
  }

  testWidgets('end of the session: complete jingle once, confetti, then it stops',
      (tester) async {
    final feedback = FakeGameFeedback();
    final rebuild = ValueNotifier(0);
    await pump(tester, feedback: feedback, rebuild: rebuild);
    await tester.pump(const Duration(milliseconds: 100));
    expect(feedback.calls, ['sessionComplete']);
    expect(find.byKey(SessionCelebration.confettiKey), findsOneWidget);

    rebuild.value++; // rebuilding the screen doesn't replay it
    await tester.pump();
    await tester.pumpAndSettle();
    expect(feedback.calls, ['sessionComplete']);
    expect(find.byKey(SessionCelebration.confettiKey), findsNothing);
  });

  testWidgets('mid-quiz batch gets the smaller celebration', (tester) async {
    final feedback = FakeGameFeedback();
    await pump(tester, feedback: feedback, big: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(feedback.calls, ['batchComplete']);
    expect(find.byKey(SessionCelebration.confettiKey), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('reduce motion: sound but no confetti', (tester) async {
    final feedback = FakeGameFeedback();
    await pump(tester, feedback: feedback, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(feedback.calls, ['sessionComplete']);
    expect(find.byKey(SessionCelebration.confettiKey), findsNothing);
  });

  testWidgets('buttons work while the confetti is flying', (tester) async {
    final feedback = FakeGameFeedback();
    var tapped = false;
    await tester.pumpWidget(feedback.provide(MaterialApp(
      home: Scaffold(
        body: SessionCelebration(
          big: true,
          child: Center(
            child: ElevatedButton(onPressed: () => tapped = true, child: const Text('Finish')),
          ),
        ),
      ),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(SessionCelebration.confettiKey), findsOneWidget);
    await tester.tap(find.text('Finish'));
    expect(tapped, isTrue);
    await tester.pumpAndSettle();
  });
}
