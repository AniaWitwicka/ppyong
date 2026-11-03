import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/card_sort.dart';

CardModel card(String id, CardStatus status) => CardModel(
      id: id,
      korean: id,
      romanisation: '',
      translation: id,
      notes: '',
      status: status,
    );

final deck = [
  card('m1', CardStatus.mastered),
  card('n1', CardStatus.newCard),
  card('l1', CardStatus.learning),
  card('n2', CardStatus.newCard),
  card('m2', CardStatus.mastered),
  card('l2', CardStatus.learning),
];

List<String> ids(List<CardModel> cards) => [for (final c in cards) c.id];

void main() {
  test('deck order leaves the list as it is', () {
    expect(ids(CardSort.deckOrder.apply(deck)), ['m1', 'n1', 'l1', 'n2', 'm2', 'l2']);
  });

  test('new first: new → learning → mastered, deck order within each', () {
    expect(ids(CardSort.newFirst.apply(deck)), ['n1', 'n2', 'l1', 'l2', 'm1', 'm2']);
  });

  test('mastered first: mastered → learning → new, deck order within each', () {
    expect(ids(CardSort.masteredFirst.apply(deck)), ['m1', 'm2', 'l1', 'l2', 'n1', 'n2']);
  });

  test('does not change the original list', () {
    final copy = List.of(deck);
    CardSort.newFirst.apply(deck);
    expect(ids(deck), ids(copy));
  });

  test('tapping cycles deck order → new first → mastered first → deck order', () {
    expect(CardSort.deckOrder.next, CardSort.newFirst);
    expect(CardSort.newFirst.next, CardSort.masteredFirst);
    expect(CardSort.masteredFirst.next, CardSort.deckOrder);
  });
}
