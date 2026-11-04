import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/collection.dart';
import 'package:ppyong/models/deck.dart';
import 'package:ppyong/models/deck_selection.dart';
import 'package:ppyong/widgets/deck_picker.dart';

Collection col(String id, String name, int decks) => Collection(
    id: id, name: name, emoji: '📚', color: Colors.green,
    deckCount: decks, wordCount: 0, dueCount: 0, progress: 0);

DeckSummary deck(String id, String name, int cards) => DeckSummary(
    id: id, name: name, cardCount: cards, masteredCount: 0, learningCount: 0, newCount: cards);

final _decks = {
  'k': [deck('d1', 'Food', 40), deck('d2', 'Home', 30), deck('d3', 'Travel', 50)],
  'j': [deck('d4', 'Kana', 20)],
};

Future<void> pumpPicker(WidgetTester tester,
    {void Function(DeckSelection)? onDone, void Function(String, String)? onDeck}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: DeckPickerScreen(
      title: 'Choose decks',
      subtitle: 'Pick one or more',
      accentColor: Colors.blue,
      onSelectionDone: onDone,
      onDeckSelected: onDeck,
      loadCollections: () async => [col('k', 'Korean', 3), col('j', 'Japanese', 1)],
      loadDecks: (id) async => _decks[id]!,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pick two decks: the button counts decks and words', (tester) async {
    DeckSelection? done;
    await pumpPicker(tester, onDone: (s) => done = s);
    expect(find.textContaining('Start ·'), findsNothing, reason: 'nothing picked yet');

    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(find.text('Start · 1 deck · 40 words'), findsOneWidget);
    await tester.tap(find.text('Travel'));
    await tester.pump();
    expect(find.text('Start · 2 decks · 90 words'), findsOneWidget);

    await tester.tap(find.text('Start · 2 decks · 90 words'));
    expect(done!.ids, ['d1', 'd3']);
    expect(done!.label, 'Food + 1 more');
  });

  testWidgets('tapping a picked deck again unpicks it', (tester) async {
    await pumpPicker(tester, onDone: (_) {});
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(find.textContaining('Start ·'), findsNothing);
  });

  testWidgets('Select all picks the whole collection, named after it', (tester) async {
    DeckSelection? done;
    await pumpPicker(tester, onDone: (s) => done = s);
    await tester.tap(find.text('Select all').first);
    await tester.pumpAndSettle();
    expect(find.text('Start · 3 decks · 120 words'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Start · 3 decks · 120 words'));
    expect(done!.ids, ['d1', 'd2', 'd3']);
    expect(done!.label, 'Korean');

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.textContaining('Start ·'), findsNothing);
  });

  testWidgets('decks from two collections mix', (tester) async {
    DeckSelection? done;
    await pumpPicker(tester, onDone: (s) => done = s);
    await tester.tap(find.text('Select all').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.tap(find.text('Start · 2 decks · 50 words'));
    expect(done!.ids, ['d4', 'd2']);
    expect(done!.collectionName, isNull);
  });

  testWidgets('single-deck mode (Matching) still picks on tap', (tester) async {
    String? picked;
    await pumpPicker(tester, onDeck: (id, _) => picked = id);
    expect(find.text('Select all'), findsNothing);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    expect(picked, 'd2');
  });
}
