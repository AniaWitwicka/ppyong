/// One deck chosen for a study session.
class DeckRef {
  const DeckRef({required this.id, required this.name, this.cardCount = 0});
  final String id;
  final String name;
  final int cardCount;

  @override
  bool operator ==(Object other) => other is DeckRef && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// The decks a study session uses: one deck, a few decks mixed together, or
/// a whole collection.
class DeckSelection {
  DeckSelection(List<DeckRef> decks, {this.collectionName})
      : assert(decks.isNotEmpty),
        decks = List.unmodifiable(decks);

  DeckSelection.single(String id, String name)
      : this([DeckRef(id: id, name: name)]);

  final List<DeckRef> decks;

  /// Set when every deck of one collection was picked.
  final String? collectionName;

  List<String> get ids => [for (final d in decks) d.id];
  bool get isSingle => decks.length == 1;
  int get cardCount => decks.fold(0, (sum, d) => sum + d.cardCount);

  /// Session name: the collection, the one deck, or "First deck + 2 more".
  String get label {
    if (collectionName != null) return collectionName!;
    if (isSingle) return decks.first.name;
    return '${decks.first.name} + ${decks.length - 1} more';
  }
}
