import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/deck_selection.dart';
import 'package:ppyong/screens/flashcard_study_screen.dart';
import 'package:ppyong/screens/multiple_choice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

CardModel card(String id) => CardModel(
    id: id, korean: 'k-$id', romanisation: '', translation: 't-$id', notes: '',
    status: CardStatus.newCard);

final _deckCards = {
  'a': [card('a1'), card('a2'), card('a3')],
  'b': [card('b1'), card('b2')],
};

Future<void> _phone(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('flashcards: two decks in one session, progress saved per word',
      (tester) async {
    await _phone(tester);
    SharedPreferences.setMockInitialValues({'study_test_after_batch': false});
    final reviewed = <String>[];
    final loaded = <String>{};
    await tester.pumpWidget(MaterialApp(
      home: FlashcardStudyScreen(
        selection: DeckSelection(const [
          DeckRef(id: 'a', name: 'Food', cardCount: 3),
          DeckRef(id: 'b', name: 'Home', cardCount: 2),
        ]),
        loadCards: (id, scope) async {
          loaded.add(id);
          return scope == '' ? _deckCards[id]! : <CardModel>[];
        },
        reviewCard: (id, _) async => reviewed.add(id),
      ),
    ));
    await tester.pumpAndSettle();

    expect(loaded, {'a', 'b'});
    expect(find.text('Food + 1 more'), findsOneWidget);
    expect(find.text('All 5 cards in one go'), findsOneWidget);
    expect(find.text('5 cards in 2 decks'), findsOneWidget);

    await tester.tap(find.text('Start studying'));
    await tester.pumpAndSettle();
    expect(find.text('1/5'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Tap to reveal').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Knew it').last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Session complete!'), findsOneWidget);
    expect(reviewed.toSet(), {'a1', 'a2', 'a3', 'b1', 'b2'});

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('last_deck_id'), isNull,
        reason: 'the Resume card keeps the last one-deck session');
  });

  testWidgets('multiple choice: wrong options come from both decks', (tester) async {
    await _phone(tester);
    // Deck "a" alone has 1 word; 3 wrong options need deck "b" too.
    final cards = {'a': [card('a1')], 'b': [card('b1'), card('b2'), card('b3')]};
    await tester.pumpWidget(MaterialApp(
      home: MultipleChoiceScreen(
        selection: DeckSelection(const [
          DeckRef(id: 'a', name: 'Food'),
          DeckRef(id: 'b', name: 'Home'),
        ]),
        loadCards: (id) async => cards[id]!,
        reviewCard: (_, __) async {},
      ),
    ));
    await tester.pumpAndSettle();

    for (final id in ['a1', 'b1', 'b2', 'b3']) {
      expect(find.text('t-$id'), findsOneWidget, reason: 'option t-$id is offered');
    }
  });
}
