import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/match_game.dart';

CardModel card(String id, String korean, String translation) => CardModel(
      id: id,
      korean: korean,
      romanisation: '',
      translation: translation,
      notes: '',
      status: CardStatus.newCard,
    );

List<CardModel> deck(int n) =>
    [for (var i = 0; i < n; i++) card('c$i', 'k$i', 't$i')];

MatchTile tileFor(MatchGame g, String id, MatchSide side) =>
    (side == MatchSide.korean ? g.koreanColumn : g.translationColumn)
        .firstWhere((t) => t.card.id == id);

/// Matches every pair on the current board correctly.
void clearBoard(MatchGame g) {
  for (final k in List.of(g.koreanColumn)) {
    g.select(k);
    g.select(tileFor(g, k.card.id, MatchSide.translation));
  }
}

void main() {
  test('deals at most pairsPerBoard cards, same cards in both columns', () {
    final g = MatchGame(cards: deck(10), pairsPerBoard: 6, random: Random(1));
    expect(g.boardSize, 6);
    expect(g.koreanColumn.map((t) => t.card.id).toSet(),
        g.translationColumn.map((t) => t.card.id).toSet());
  });

  test('never repeats a card and the last board can be smaller', () {
    final g = MatchGame(cards: deck(10), pairsPerBoard: 6, random: Random(2));
    final dealt = <String>[...g.koreanColumn.map((t) => t.card.id)];
    clearBoard(g);
    g.dealBoard();
    expect(g.boardSize, 4);
    dealt.addAll(g.koreanColumn.map((t) => t.card.id));
    expect(dealt.toSet().length, 10);
    clearBoard(g);
    expect(g.deckFinished, isTrue);
  });

  test('correct pair is matched, counted and then ignored', () {
    final g = MatchGame(cards: deck(3), pairsPerBoard: 3, random: Random(3));
    final k = tileFor(g, 'c0', MatchSide.korean);
    final t = tileFor(g, 'c0', MatchSide.translation);
    expect(g.select(k), MatchOutcome.selected);
    expect(g.select(t), MatchOutcome.correct);
    expect(g.matched, 1);
    expect(g.isMatched(k) && g.isMatched(t), isTrue);
    expect(g.select(k), MatchOutcome.ignored);
  });

  test('works in either order and wrong pairs count as mistakes', () {
    final g = MatchGame(cards: deck(3), pairsPerBoard: 3, random: Random(4));
    g.select(tileFor(g, 'c1', MatchSide.translation));
    expect(g.select(tileFor(g, 'c2', MatchSide.korean)), MatchOutcome.wrong);
    expect(g.mistakes, 1);
    expect(g.selected, isNull);
    g.select(tileFor(g, 'c2', MatchSide.translation));
    expect(g.select(tileFor(g, 'c2', MatchSide.korean)), MatchOutcome.correct);
    expect(g.accuracy, 0.5);
  });

  test('tapping the same side moves the selection, same tile deselects', () {
    final g = MatchGame(cards: deck(3), pairsPerBoard: 3, random: Random(5));
    final a = tileFor(g, 'c0', MatchSide.korean);
    final b = tileFor(g, 'c1', MatchSide.korean);
    g.select(a);
    expect(g.select(b), MatchOutcome.selected);
    expect(g.selected, b);
    expect(g.select(b), MatchOutcome.deselected);
    expect(g.selected, isNull);
    expect(g.mistakes, 0);
  });

  test('cards with the same translation never share a board', () {
    final cards = [
      card('a', '고치다', 'naprawiać'),
      card('b', '수리하다', 'Naprawiać '),
      ...deck(4),
    ];
    for (var seed = 0; seed < 20; seed++) {
      final g = MatchGame(cards: cards, pairsPerBoard: 6, random: Random(seed));
      var boards = 0;
      while (true) {
        final ids = g.koreanColumn.map((t) => t.card.id).toSet();
        expect(ids.containsAll(['a', 'b']), isFalse, reason: 'seed $seed');
        boards++;
        clearBoard(g);
        if (g.deckFinished) break;
        g.dealBoard();
      }
      expect(boards, 2, reason: 'seed $seed');
    }
  });

  test('only cards in 2+ wrong pairs are marked for review', () {
    final g = MatchGame(cards: deck(4), pairsPerBoard: 4, random: Random(7));
    // c0 is wrong twice (with c1, then c2); c1 and c2 only once each.
    g.select(tileFor(g, 'c0', MatchSide.korean));
    g.select(tileFor(g, 'c1', MatchSide.translation));
    expect(g.cardsToReview, isEmpty);
    g.select(tileFor(g, 'c2', MatchSide.translation));
    g.select(tileFor(g, 'c0', MatchSide.korean));
    expect(g.cardsToReview.map((c) => c.id), ['c0']);
    // Matching it correctly afterwards keeps it marked.
    g.select(tileFor(g, 'c0', MatchSide.korean));
    g.select(tileFor(g, 'c0', MatchSide.translation));
    expect(g.cardsToReview.map((c) => c.id), ['c0']);
    // Correct matches never mark a card.
    g.select(tileFor(g, 'c3', MatchSide.korean));
    g.select(tileFor(g, 'c3', MatchSide.translation));
    expect(g.cardsToReview.map((c) => c.id), ['c0']);
  });

  test('pair is correct when the translation text matches', () {
    final cards = [card('a', '고치다', 'naprawiać'), card('b', '수리하다', 'naprawiać')];
    final g = MatchGame(cards: cards, pairsPerBoard: 2, random: Random(6));
    final onBoard = g.koreanColumn.single.card;
    final other = cards.firstWhere((c) => c.id != onBoard.id);
    // A korean tile and a translation tile from different cards with equal text.
    final fake = MatchTile(other, MatchSide.translation);
    g.select(g.koreanColumn.single);
    expect(g.select(fake), MatchOutcome.correct);
  });
}
