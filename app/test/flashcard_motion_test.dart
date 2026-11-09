import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/screens/flashcard_study_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_game_feedback.dart';

CardModel card(int i) => CardModel(
      id: 'c$i',
      korean: 'k$i',
      romanisation: '',
      translation: 't$i',
      notes: 'a longer note so the back of the card has more lines on it',
      status: CardStatus.newCard,
    );

Future<void> openStudy(WidgetTester tester, {FakeGameFeedback? feedback}) async {
  SharedPreferences.setMockInitialValues({'study_test_after_batch': false});
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final cards = [for (var i = 0; i < 3; i++) card(i)];
  final app = MaterialApp(
    home: FlashcardStudyScreen(
      deckId: 'd1',
      deckName: 'Test deck',
      loadCards: (_, scope) async => scope == '' ? cards : <CardModel>[],
      reviewCard: (_, __) async {},
    ),
  );
  await tester.pumpWidget(feedback?.provide(app) ?? app);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start studying'));
  await tester.pumpAndSettle();
}

/// The white card face holding [text].
Finder face(String text) => find
    .ancestor(of: find.text(text), matching: find.byType(AnimatedContainer))
    .first;

/// How visible the card holding [text] is (the card's own fade).
double cardOpacity(WidgetTester tester, String text) => tester
    .widgetList<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)))
    .map((o) => o.opacity)
    .reduce((a, b) => a * b);

/// The Korean word on the card now on screen (k0, k1, …).
String currentKorean(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((s) => RegExp(r'^k\d$').hasMatch(s));

void main() {
  testWidgets('the card keeps its size when it flips and the buttons appear',
      (tester) async {
    await openStudy(tester);
    final before = tester.getRect(face('k0'));

    await tester.tap(find.text('Tap to reveal').first);
    await tester.pumpAndSettle();
    expect(find.text('Knew it'), findsWidgets);
    final after = tester.getRect(face('t0'));

    expect(after.height, before.height);
    expect(after.width, before.width);
    expect(after.top, before.top);
  });

  testWidgets('the next card fades in where it belongs instead of popping in sideways',
      (tester) async {
    await openStudy(tester);
    final first = currentKorean(tester);
    final settled = tester.getRect(face(first));

    await tester.tap(find.text('Tap to reveal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knew it').last);
    await tester.pump(); // the leaving animation starts on this frame
    await tester.pump(const Duration(milliseconds: 270)); // first card has left
    await tester.pump(const Duration(milliseconds: 16)); // next card's first frame

    final next = currentKorean(tester);
    expect(next, isNot(first));
    expect(cardOpacity(tester, next), lessThan(0.3), reason: 'starts nearly invisible');
    final entering = tester.getRect(face(next));
    expect((entering.center.dx - settled.center.dx).abs(), lessThan(2),
        reason: 'no sideways jump');

    await tester.pumpAndSettle();
    expect(cardOpacity(tester, next), 1.0);
    expect(tester.getRect(face(next)), settled);
  });

  testWidgets('the swipe tint reads the right way round on a turned card', (tester) async {
    await openStudy(tester);
    await tester.tap(find.text('Tap to reveal').first);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(face('t0')));
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    expect(find.text('Keep trying'), findsOneWidget);
    final mirrored = tester
        .widgetList<Transform>(
            find.ancestor(of: find.text('Keep trying'), matching: find.byType(Transform)))
        .where((t) => t.transform.entry(0, 0) < 0);
    expect(mirrored, isEmpty, reason: 'no flip rotation above the tint text');

    await gesture.up(); // short drag: the card goes back
    await tester.pumpAndSettle();
    expect(find.text('Keep trying'), findsNothing);
    expect(find.text('t0'), findsOneWidget);
  });

  group('feedback', () {
    Future<void> flip(WidgetTester tester) async {
      await tester.tap(find.text('Tap to reveal').first);
      await tester.pumpAndSettle();
    }

    Future<void> swipe(WidgetTester tester, double dx) async {
      final gesture = await tester.startGesture(tester.getCenter(face(
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '')
              .firstWhere((s) => RegExp(r'^t\d$').hasMatch(s)))));
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(Offset(dx / 5, 0));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('flip → swish; buttons: Knew it → correct, Again → soft',
        (tester) async {
      final feedback = FakeGameFeedback();
      await openStudy(tester, feedback: feedback);
      expect(feedback.calls, isEmpty, reason: 'nothing plays on open');

      await flip(tester);
      expect(feedback.calls, ['flip']);
      await tester.tap(face('t0'));
      await tester.pumpAndSettle();
      expect(feedback.calls, ['flip'], reason: 'tapping a turned card is silent');

      await tester.tap(find.text('Knew it').last);
      await tester.pump();
      expect(feedback.calls, ['flip', 'correct'], reason: 'plays the moment it is rated');
      await tester.pumpAndSettle();

      await flip(tester);
      await tester.tap(find.text('Again'));
      await tester.pump();
      await tester.tap(find.text('Again'), warnIfMissed: false); // double tap
      await tester.pumpAndSettle();
      expect(feedback.calls, ['flip', 'correct', 'flip', 'again']);
    });

    testWidgets('swipes: right → correct, left → soft again, let go early → nothing',
        (tester) async {
      final feedback = FakeGameFeedback();
      await openStudy(tester, feedback: feedback);
      await flip(tester);
      feedback.calls.clear();

      await swipe(tester, 50); // short drag: the card goes back
      expect(feedback.calls, isEmpty);
      await swipe(tester, -50);
      expect(feedback.calls, isEmpty);

      await swipe(tester, 200);
      expect(feedback.calls, ['correct']);

      await flip(tester);
      await swipe(tester, -200);
      expect(feedback.calls, ['correct', 'flip', 'again']);
    });

    testWidgets('dragging a card that is not turned yet plays nothing', (tester) async {
      final feedback = FakeGameFeedback();
      await openStudy(tester, feedback: feedback);
      final gesture = await tester.startGesture(tester.getCenter(face('k0')));
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(feedback.calls, isEmpty);
    });
  });
}
