import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/deck_selection.dart';
import 'package:ppyong/screens/multiple_choice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_game_feedback.dart';

CardModel card(String id) => CardModel(
    id: id, korean: 'k-$id', romanisation: '', translation: 't-$id', notes: '',
    status: CardStatus.newCard);

final _cards = [for (var i = 1; i <= 12; i++) card('w$i')];

Future<List<String>> openQuiz(WidgetTester tester, {FakeGameFeedback? feedback}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final reviewed = <String>[];
  final app = MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultipleChoiceScreen(
                  selection: DeckSelection.single('d1', 'Jedzenie'),
                  loadCards: (_) async => _cards,
                  reviewCard: (id, correct) async => reviewed.add(id),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(feedback?.provide(app) ?? app);
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return reviewed;
}

String currentWord(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((s) => s.startsWith('k-'))
    .substring(2);

/// Picks the right option for the word on screen; the quiz moves on by itself.
Future<void> answerRight(WidgetTester tester) async {
  await tester.tap(find.text('t-${currentWord(tester)}'));
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
}

/// Picks a wrong option, then Next.
Future<void> answerWrong(WidgetTester tester) async {
  final word = currentWord(tester);
  await tester.tap(find
      .byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('t-') && w.data != 't-$word')
      .first);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next →'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('answers give feedback once: right → correct, wrong → wrong, Next is silent',
      (tester) async {
    SharedPreferences.setMockInitialValues({'study_session_size': 10});
    final feedback = FakeGameFeedback();
    await openQuiz(tester, feedback: feedback);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(feedback.calls, isEmpty, reason: 'nothing plays on screen open');

    // Right answer: one "correct" the moment it's tapped, before moving on.
    await tester.tap(find.text('t-${currentWord(tester)}'));
    await tester.pump();
    expect(feedback.calls, ['correct']);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 10'), findsOneWidget);

    // Wrong answer: one "wrong"; tapping more options does nothing.
    final word = currentWord(tester);
    final wrongOptions = find.byWidgetPredicate((w) =>
        w is Text && (w.data ?? '').startsWith('t-') && w.data != 't-$word');
    await tester.tap(wrongOptions.first);
    await tester.pump();
    expect(feedback.calls, ['correct', 'wrong']);
    await tester.tap(wrongOptions.last);
    await tester.tap(find.text('t-$word'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(feedback.calls, ['correct', 'wrong']);

    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();
    expect(find.text('Question 3 of 10'), findsOneWidget);
    expect(feedback.calls, ['correct', 'wrong'], reason: 'Next is navigation, not an answer');
  });

  testWidgets('quiz runs in batches of the saved size, no word twice', (tester) async {
    SharedPreferences.setMockInitialValues({'study_session_size': 10});
    final reviewed = await openQuiz(tester);

    expect(find.text('Words per session'), findsOneWidget);
    expect(find.text('12 cards → 2 sessions of up to 10'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 10'), findsOneWidget);

    for (var i = 0; i < 10; i++) {
      await answerRight(tester);
    }
    expect(find.text('Batch complete!'), findsOneWidget);
    expect(find.text('Jedzenie · Batch 1 of 2'), findsOneWidget);
    expect(find.text('2 words left to go'), findsOneWidget);
    expect(reviewed.length, 10, reason: 'each answer is saved straight away');

    await tester.tap(find.text('Next 2 words'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 2'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await answerRight(tester);
    }
    expect(find.text('Quiz complete!'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(reviewed.toSet(), {for (final c in _cards) c.id});
    expect(reviewed.length, 12);
  });

  testWidgets('a mid-quiz batch gets the small celebration, the last one the full one',
      (tester) async {
    SharedPreferences.setMockInitialValues({'study_session_size': 10});
    final feedback = FakeGameFeedback();
    await openQuiz(tester, feedback: feedback);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    await answerWrong(tester); // same celebration at any score
    for (var i = 1; i < 10; i++) {
      await answerRight(tester);
    }
    expect(find.text('10 words practised'), findsOneWidget);
    expect(feedback.calls.where((c) => c.endsWith('Complete')), ['batchComplete']);

    await tester.tap(find.text('Next 2 words'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await answerRight(tester);
    }
    expect(find.text('2 words practised · Perfect round!'), findsOneWidget);
    expect(feedback.calls.where((c) => c.endsWith('Complete')),
        ['batchComplete', 'sessionComplete']);
  });

  testWidgets('the batch size picked is remembered for next time', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openQuiz(tester);
    expect(find.text('12 cards → 1 sessions of up to 20'), findsNothing);
    expect(find.text('All 12 cards in one go'), findsOneWidget,
        reason: 'default is 20, more than the deck');

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('12 cards → 2 sessions of up to 10'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('study_session_size'), 10);
  });

  testWidgets('a right answer moves on by itself; a wrong one waits for Next',
      (tester) async {
    SharedPreferences.setMockInitialValues({'study_session_size': 10});
    final reviewed = await openQuiz(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('t-${currentWord(tester)}'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Question 1 of 10'), findsOneWidget,
        reason: 'the green answer stays on screen for a moment');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 10'), findsOneWidget);

    final word = currentWord(tester);
    await tester.tap(find.byWidgetPredicate((w) =>
        w is Text && (w.data ?? '').startsWith('t-') && w.data != 't-$word').first);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 10'), findsOneWidget,
        reason: 'a wrong answer waits so the right one can be read');
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();
    expect(find.text('Question 3 of 10'), findsOneWidget);
    expect(reviewed, hasLength(2));
  });

  testWidgets('Finish after a batch leaves the quiz', (tester) async {
    SharedPreferences.setMockInitialValues({'study_session_size': 10});
    final reviewed = await openQuiz(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await answerRight(tester);
    }
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(reviewed.length, 10);
  });
}
