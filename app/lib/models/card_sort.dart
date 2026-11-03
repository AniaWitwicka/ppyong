import 'card.dart';

/// How the deck page lists its cards. Tapping "Sort by status" cycles
/// deck order → new first → mastered first → deck order.
enum CardSort {
  deckOrder('Sort by status'),
  newFirst('New first'),
  masteredFirst('Mastered first');

  const CardSort(this.label);
  final String label;

  CardSort get next => CardSort.values[(index + 1) % CardSort.values.length];

  /// [cards] in this order. Cards with the same status keep their deck order.
  List<CardModel> apply(List<CardModel> cards) {
    if (this == CardSort.deckOrder) return cards;
    final rank = this == CardSort.newFirst ? _newFirstRank : _masteredFirstRank;
    final indexed = cards.indexed.toList()
      ..sort((a, b) {
        final byStatus = rank[a.$2.status]!.compareTo(rank[b.$2.status]!);
        return byStatus != 0 ? byStatus : a.$1.compareTo(b.$1);
      });
    return [for (final (_, c) in indexed) c];
  }

  static const _newFirstRank = {
    CardStatus.newCard: 0,
    CardStatus.learning: 1,
    CardStatus.mastered: 2,
  };
  static const _masteredFirstRank = {
    CardStatus.mastered: 0,
    CardStatus.learning: 1,
    CardStatus.newCard: 2,
  };
}
