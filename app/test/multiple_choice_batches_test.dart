import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/deck_selection.dart';
import 'package:ppyong/screens/multiple_choice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

CardModel card(String id) => CardModel(
    id: id, korean: 'k-$id', romanisation: '', translation: 't-$id', notes: '',
    status: CardStatus.newCard);

final _cards = [for (var i = 1; i <= 12; i++) card('w$i')];

Future<List<String>> openQuiz(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final reviewed = <String>[];
  await tester.pumpWidget(MaterialApp(
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
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return reviewed;
}

/// Picks the right option for the word on screen, then presses Next.
Future<void> answerRight(WidgetTester tester) async {
  final prompt = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('k-'));
  await tester.tap(find.text('t-${prompt.substring(2)}'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next →'));
  await tester.pumpAndSettle();
}

void main() {
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
