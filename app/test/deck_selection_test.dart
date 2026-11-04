import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/deck_selection.dart';
import 'package:ppyong/services/card_service.dart';

CardModel card(String id) => CardModel(
    id: id, korean: id, romanisation: '', translation: id, notes: '', status: CardStatus.newCard);

void main() {
  const a = DeckRef(id: 'a', name: 'Food', cardCount: 40);
  const b = DeckRef(id: 'b', name: 'Home', cardCount: 30);
  const c = DeckRef(id: 'c', name: 'Travel', cardCount: 50);

  test('one deck is named after the deck', () {
    final s = DeckSelection.single('a', 'Food');
    expect(s.isSingle, isTrue);
    expect(s.label, 'Food');
    expect(s.ids, ['a']);
  });

  test('a few decks: first deck + N more, words add up', () {
    final s = DeckSelection([a, b, c]);
    expect(s.isSingle, isFalse);
    expect(s.label, 'Food + 2 more');
    expect(s.ids, ['a', 'b', 'c']);
    expect(s.cardCount, 120);
  });

  test('a whole collection is named after the collection', () {
    expect(DeckSelection([a, b], collectionName: '한국어 Chikas').label, '한국어 Chikas');
  });

  test('joinDeckCards loads every deck and keeps deck order', () async {
    final loaded = <String>[];
    final cards = await joinDeckCards(['a', 'b'], (id) async {
      loaded.add(id);
      return [card('${id}1'), card('${id}2')];
    });
    expect(loaded, unorderedEquals(['a', 'b']));
    expect(cards.map((c) => c.id), ['a1', 'a2', 'b1', 'b2']);
  });
}
