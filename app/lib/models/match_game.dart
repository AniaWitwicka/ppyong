import 'dart:math';
import 'card.dart';

enum MatchSide { korean, translation }

/// One tappable tile on the board: a card shown from one side.
class MatchTile {
  const MatchTile(this.card, this.side);
  final CardModel card;
  final MatchSide side;

  String get label => side == MatchSide.korean ? card.korean : card.translation;

  @override
  bool operator ==(Object other) =>
      other is MatchTile && other.card.id == card.id && other.side == side;

  @override
  int get hashCode => Object.hash(card.id, side);
}

/// What happened after a tap, so the screen can animate it.
enum MatchOutcome { selected, deselected, correct, wrong, ignored }

/// Rules of the matching game, kept free of widgets so they can be unit-tested.
///
/// Cards are dealt from the deck in random order without repeats, at most
/// [pairsPerBoard] per board. Two cards with the same translation never share
/// a board, and a pair counts as correct when the translation text matches.
class MatchGame {
  MatchGame({
    required List<CardModel> cards,
    required this.pairsPerBoard,
    Random? random,
  })  : _random = random ?? Random(),
        _queue = List<CardModel>.from(cards)..shuffle(random ?? Random()) {
    dealBoard();
  }

  final int pairsPerBoard;
  final Random _random;
  final List<CardModel> _queue;

  List<MatchTile> koreanColumn = [];
  List<MatchTile> translationColumn = [];
  final Set<MatchTile> _matchedTiles = {};

  MatchTile? selected;
  int matched = 0;
  int mistakes = 0;

  /// A card that is part of this many wrong pairs in one game counts as "didn't know".
  static const mistakesToReview = 2;
  final Map<String, CardModel> _cardsById = {};
  final Map<String, int> _wrongCounts = {};

  /// The two tiles of the last correct or wrong pair, for animations.
  List<MatchTile> lastPair = const [];

  int get boardSize => koreanColumn.length;
  bool get boardCleared => _matchedTiles.length == koreanColumn.length * 2;
  bool get deckFinished => boardCleared && _queue.isEmpty;
  int get cardsLeftInDeck => _queue.length;

  double get accuracy {
    final attempts = matched + mistakes;
    return attempts == 0 ? 0 : matched / attempts;
  }

  bool isMatched(MatchTile tile) => _matchedTiles.contains(tile);

  /// Cards that were part of at least [mistakesToReview] wrong pairs this game.
  /// Both cards of a wrong pair count: either word may be the one not known.
  List<CardModel> get cardsToReview => [
        for (final e in _wrongCounts.entries)
          if (e.value >= mistakesToReview) _cardsById[e.key]!,
      ];

  static String _key(String translation) => translation.trim().toLowerCase();

  /// Deals the next board from the deck. Does nothing once the deck is empty.
  void dealBoard() {
    final board = <CardModel>[];
    final seen = <String>{};
    for (var i = 0; i < _queue.length && board.length < pairsPerBoard;) {
      final card = _queue[i];
      if (seen.add(_key(card.translation))) {
        board.add(_queue.removeAt(i));
      } else {
        i++;
      }
    }
    if (board.isEmpty) return;
    _matchedTiles.clear();
    selected = null;
    lastPair = const [];
    koreanColumn = [for (final c in board) MatchTile(c, MatchSide.korean)]..shuffle(_random);
    translationColumn = [for (final c in board) MatchTile(c, MatchSide.translation)]
      ..shuffle(_random);
  }

  MatchOutcome select(MatchTile tile) {
    if (isMatched(tile)) return MatchOutcome.ignored;
    final current = selected;
    if (current == null || current.side == tile.side) {
      if (current == tile) {
        selected = null;
        return MatchOutcome.deselected;
      }
      selected = tile;
      return MatchOutcome.selected;
    }

    selected = null;
    lastPair = [current, tile];
    if (_key(current.card.translation) == _key(tile.card.translation)) {
      _matchedTiles.addAll([current, tile]);
      matched++;
      return MatchOutcome.correct;
    }
    mistakes++;
    for (final card in {current.card.id: current.card, tile.card.id: tile.card}.values) {
      _cardsById[card.id] = card;
      _wrongCounts[card.id] = (_wrongCounts[card.id] ?? 0) + 1;
    }
    return MatchOutcome.wrong;
  }
}
