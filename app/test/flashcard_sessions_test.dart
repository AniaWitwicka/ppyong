import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/screens/flashcard_study_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

CardModel card(int i) => CardModel(
      id: 'c$i',
      korean: 'k$i',
      romanisation: '',
      translation: 't$i',
      notes: '',
      status: CardStatus.newCard,
    );

class _Harness {
  final reviewed = <String>[];

  /// Opens the study screen; the test after each batch is off unless [prefs]
  /// turn it on (that flow is covered in flashcard_batch_test_test.dart).
  Future<void> open(WidgetTester tester, int deckSize,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues({'study_test_after_batch': false, ...prefs});
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cards = [for (var i = 0; i < deckSize; i++) card(i)];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardStudyScreen(
                  deckId: 'd1',
                  deckName: 'Test deck',
                  loadCards: (_, scope) async => scope == '' ? cards : <CardModel>[],
                  reviewCard: (id, _) async => reviewed.add(id),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('Start studying'));
    await tester.pumpAndSettle();
  }

  /// Flips the current card and taps "Knew it".
  Future<void> answer(WidgetTester tester) async {
    await tester.tap(find.text('Tap to reveal').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knew it').last);
    await tester.pumpAndSettle();
  }

  Future<void> answerAll(WidgetTester tester, int n) async {
    for (var i = 0; i < n; i++) {
      await answer(tester);
    }
  }
}

void main() {
  testWidgets('default is 20 words per session with a hint', (tester) async {
    final h = _Harness();
    await h.open(tester, 61);
    expect(find.text('Words per session'), findsOneWidget);
    expect(find.text('61 cards → 4 sessions of up to 20'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(find.text('All 61 cards in one go'), findsOneWidget);
  });

  testWidgets('a 25-card deck in sessions of 10: 10 → 10 → 5, no repeats', (tester) async {
    final h = _Harness();
    await h.open(tester, 25);
    await tester.tap(find.text('10'));
    await tester.pump();
    expect(find.text('25 cards → 3 sessions of up to 10'), findsOneWidget);
    await h.start(tester);

    expect(find.text('1/10'), findsOneWidget, reason: 'progress is per session');
    await h.answerAll(tester, 10);
    expect(find.text('Session complete!'), findsOneWidget);
    expect(find.text('Test deck · Session 1 of 3'), findsOneWidget);
    expect(find.text('15 words left to go'), findsOneWidget);
    expect(find.text('Done for now'), findsOneWidget);

    await tester.tap(find.text('Next 10 words'));
    await tester.pumpAndSettle();
    expect(find.text('1/10'), findsOneWidget);
    await h.answerAll(tester, 10);
    expect(find.text('Test deck · Session 2 of 3'), findsOneWidget);
    expect(find.text('5 words left to go'), findsOneWidget);

    await tester.tap(find.text('Next 5 words'));
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
    await h.answerAll(tester, 5);

    expect(find.text('All sessions done!'), findsOneWidget);
    expect(find.text('Study again'), findsOneWidget);
    expect(find.text('Back to deck'), findsOneWidget);
    expect(h.reviewed, hasLength(25));
    expect(h.reviewed.toSet(), hasLength(25), reason: 'every word reviewed once');
  });

  testWidgets('"Done for now" leaves the study screen', (tester) async {
    final h = _Harness();
    await h.open(tester, 12);
    await tester.tap(find.text('10'));
    await tester.pump();
    await h.start(tester);
    await h.answerAll(tester, 10);

    await tester.tap(find.text('Done for now'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(h.reviewed, hasLength(10));
  });

  testWidgets('a deck smaller than the session is one session', (tester) async {
    final h = _Harness();
    await h.open(tester, 4);
    expect(find.text('All 4 cards in one go'), findsOneWidget);
    await h.start(tester);
    expect(find.text('1/4'), findsOneWidget);
    await h.answerAll(tester, 4);
    expect(find.text('Session complete!'), findsOneWidget);
    expect(find.textContaining('left to go'), findsNothing);
    expect(find.text('Study again'), findsOneWidget);
  });

  testWidgets('the chosen session size is remembered', (tester) async {
    final h = _Harness();
    await h.open(tester, 30, prefs: {'study_session_size': 15});
    expect(find.text('30 cards → 2 sessions of up to 15'), findsOneWidget);

    await tester.tap(find.text('10'));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('study_session_size'), 10);
  });
}
