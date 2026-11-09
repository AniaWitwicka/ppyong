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
      notes: '',
      status: CardStatus.newCard,
    );

/// Saved reviews as (card id, knew it).
final reviewed = <(String, bool)>[];

Future<void> open(WidgetTester tester, int deckSize,
    {Map<String, Object> prefs = const {}, FakeGameFeedback? feedback}) async {
  reviewed.clear();
  SharedPreferences.setMockInitialValues({'study_session_size': 10, ...prefs});
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final cards = [for (var i = 0; i < deckSize; i++) card(i)];
  final app = MaterialApp(
    home: FlashcardStudyScreen(
      deckId: 'd1',
      deckName: 'Test deck',
      loadCards: (_, scope) async => scope == '' ? cards : <CardModel>[],
      reviewCard: (id, knew) async => reviewed.add((id, knew)),
    ),
  );
  await tester.pumpWidget(feedback?.provide(app) ?? app);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start studying'));
  await tester.pumpAndSettle();
}

/// The word on the current flashcard or test question, e.g. "k3".
String currentKorean(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((d) => RegExp(r'^k\d+$').hasMatch(d));

Future<void> swipe(WidgetTester tester, {required bool knew}) async {
  await tester.tap(find.text('Tap to reveal').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(knew ? 'Knew it' : 'Again').last);
  await tester.pumpAndSettle();
}

/// Answers the current test question. A right answer moves on by itself;
/// a wrong one waits for Next.
Future<void> answer(WidgetTester tester, {required bool right}) async {
  final i = currentKorean(tester).substring(1);
  final option = right
      ? find.text('t$i')
      : find.byWidgetPredicate((w) =>
          w is Text && RegExp(r'^t\d+$').hasMatch(w.data ?? '') && w.data != 't$i');
  await tester.tap(option.first);
  if (right) {
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    return;
  }
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next →'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the test is on by default', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: FlashcardStudyScreen(
        deckId: 'd1',
        deckName: 'Test deck',
        loadCards: (_, __) async => <CardModel>[],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Test after each batch'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('study_test_after_batch'), isFalse);
  });

  testWidgets('"Again" sends a card back; the test starts once all are known', (tester) async {
    await open(tester, 3);
    final first = currentKorean(tester);
    await swipe(tester, knew: false);
    await swipe(tester, knew: true);
    await swipe(tester, knew: true);
    expect(currentKorean(tester), first, reason: 'the "Again" card returns');
    expect(find.text('3/3'), findsOneWidget);
    await swipe(tester, knew: false);
    expect(currentKorean(tester), first, reason: 'still not known');
    expect(find.text('WHAT DOES THIS MEAN?'), findsNothing);

    await swipe(tester, knew: true);
    expect(find.text('WHAT DOES THIS MEAN?'), findsOneWidget);
    expect(find.text('Quick test · 1 of 3'), findsOneWidget);
    expect(reviewed, isEmpty, reason: 'swipes are only a self-check');
  });

  testWidgets('only first-try test answers are saved; misses come back', (tester) async {
    await open(tester, 3);
    for (var i = 0; i < 3; i++) {
      await swipe(tester, knew: true);
    }

    final missed = currentKorean(tester);
    await answer(tester, right: false);
    await answer(tester, right: true);
    await answer(tester, right: true);
    expect(find.text('Quick test · one more try'), findsOneWidget);
    expect(currentKorean(tester), missed);
    await answer(tester, right: true);

    expect(find.text('Session complete!'), findsOneWidget);
    expect(find.text('2 / 3 remembered — 1 will come back sooner'), findsOneWidget);
    expect(find.text('Remembered'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    final missedId = 'c${missed.substring(1)}';
    expect(reviewed, hasLength(3), reason: 'one save per word, retries not saved');
    expect(reviewed.where((r) => r.$1 == missedId).single.$2, isFalse);
    expect(reviewed.where((r) => r.$1 != missedId).every((r) => r.$2), isTrue);
  });

  testWidgets('quick test answers give feedback once each', (tester) async {
    final feedback = FakeGameFeedback();
    await open(tester, 2, feedback: feedback);
    for (var i = 0; i < 2; i++) {
      await swipe(tester, knew: true);
    }
    expect(find.text('Quick test · 1 of 2'), findsOneWidget);
    final before = feedback.calls.length; // swipes are HRHTA-107, not counted here

    final i = currentKorean(tester).substring(1);
    await tester.tap(find.text('t$i'));
    await tester.pump();
    expect(feedback.calls.sublist(before), ['correct']);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    final j = currentKorean(tester).substring(1);
    final wrong = find.byWidgetPredicate((w) =>
        w is Text && RegExp(r'^t\d+$').hasMatch(w.data ?? '') && w.data != 't$j');
    await tester.tap(wrong.first);
    await tester.pump();
    await tester.tap(find.text('t$j'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(feedback.calls.sublist(before), ['correct', 'wrong']);
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();
    expect(feedback.calls.sublist(before), ['correct', 'wrong']);
  });

  testWidgets('a right test answer moves on by itself; a wrong one waits for Next',
      (tester) async {
    await open(tester, 3);
    for (var i = 0; i < 3; i++) {
      await swipe(tester, knew: true);
    }
    expect(find.text('Quick test · 1 of 3'), findsOneWidget);

    final i = currentKorean(tester).substring(1);
    await tester.tap(find.text('t$i'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Quick test · 1 of 3'), findsOneWidget,
        reason: 'the green answer stays on screen for a moment');
    final next = tester.widget<AnimatedOpacity>(find.ancestor(
        of: find.text('Next →'), matching: find.byType(AnimatedOpacity)));
    expect(next.opacity, 0, reason: 'no Next button after a right answer');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Quick test · 2 of 3'), findsOneWidget);

    final j = currentKorean(tester).substring(1);
    await tester.tap(find.byWidgetPredicate((w) =>
        w is Text && RegExp(r'^t\d+$').hasMatch(w.data ?? '') && w.data != 't$j').first);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Quick test · 2 of 3'), findsOneWidget,
        reason: 'a wrong answer waits so the right one can be read');
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();
    expect(find.text('Quick test · 3 of 3'), findsOneWidget);
    expect(reviewed, hasLength(2));
  });

  testWidgets('batches of 10: test each batch, then the next batch', (tester) async {
    final feedback = FakeGameFeedback();
    List<String> wins() => feedback.calls.where((c) => c.endsWith('Complete')).toList();
    await open(tester, 12, feedback: feedback);
    for (var i = 0; i < 10; i++) {
      await swipe(tester, knew: true);
    }
    expect(find.text('Quick test · 1 of 10'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await answer(tester, right: true);
    }
    expect(find.text('All 10 remembered!'), findsOneWidget);
    expect(find.text('10 words practised · Perfect round!'), findsOneWidget);
    expect(find.text('2 words left to go'), findsOneWidget);
    expect(wins(), ['batchComplete']);

    await tester.tap(find.text('Next 2 words'));
    await tester.pumpAndSettle();
    await swipe(tester, knew: true);
    await swipe(tester, knew: true);
    expect(find.text('Quick test · 1 of 2'), findsOneWidget);
    await answer(tester, right: true);
    await answer(tester, right: true);
    expect(find.text('All sessions done!'), findsOneWidget);
    expect(wins(), ['batchComplete', 'sessionComplete']);
    expect(reviewed.map((r) => r.$1).toSet(), hasLength(12));
  });

  testWidgets('with the test off every swipe saves, and "Again" is not repeated', (tester) async {
    await open(tester, 2, prefs: {'study_test_after_batch': false});
    await swipe(tester, knew: false);
    await swipe(tester, knew: true);
    expect(find.text('Session complete!'), findsOneWidget);
    expect(reviewed.map((r) => r.$2), [false, true]);
  });

  testWidgets('translation → Korean test asks the other way round', (tester) async {
    reviewed.clear();
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cards = [card(0), card(1)];
    await tester.pumpWidget(MaterialApp(
      home: FlashcardStudyScreen(
        deckId: 'd1',
        deckName: 'Test deck',
        loadCards: (_, scope) async => scope == '' ? cards : <CardModel>[],
        reviewCard: (id, knew) async => reviewed.add((id, knew)),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Translation → Korean'));
    await tester.tap(find.text('Start studying'));
    await tester.pumpAndSettle();
    await swipe(tester, knew: true);
    await swipe(tester, knew: true);
    expect(find.text('HOW DO YOU SAY THIS IN KOREAN?'), findsOneWidget);
    expect(find.text('k0'), findsOneWidget);
    expect(find.text('k1'), findsOneWidget);
  });

  testWidgets('a word skipped from the front side is still in the batch test (HRHTA-126)',
      (tester) async {
    await open(tester, 4);
    final skipped = currentKorean(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.text(skipped)));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(40, 0));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(currentKorean(tester), isNot(skipped));
    for (var i = 1; i < 4; i++) {
      await swipe(tester, knew: true);
    }
    expect(reviewed, isEmpty, reason: 'with the test on, only the test counts');

    final asked = <String>{};
    for (var i = 0; i < 4; i++) {
      asked.add(currentKorean(tester));
      await answer(tester, right: true);
    }
    expect(asked, contains(skipped));
    expect(reviewed.map((r) => r.$1), contains('c${skipped.substring(1)}'));
  });
}
