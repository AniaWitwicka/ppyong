import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/batch_test.dart';
import 'package:ppyong/models/card.dart';

CardModel card(int i, {String? translation}) => CardModel(
      id: 'c$i',
      korean: 'k$i',
      romanisation: 'r$i',
      translation: translation ?? 't$i',
      notes: '',
      status: CardStatus.newCard,
    );

final deck = [for (var i = 0; i < 12; i++) card(i)];

void main() {
  test('asks each batch word once, with up to 4 distinct options from the deck', () {
    final batch = deck.sublist(0, 5);
    final t = BatchTest(batch, deck, koreanPrompt: true, rng: Random(1));
    expect(t.length, 5);
    final asked = <String>{};
    do {
      final q = t.current;
      asked.add(q.card.id);
      expect(q.prompt, q.card.korean);
      expect(q.hint, q.card.romanisation);
      expect(q.options, hasLength(4));
      expect(q.options.toSet(), hasLength(4));
      expect(q.options[q.correctIndex], q.card.translation);
      expect(q.options.every((o) => deck.any((c) => c.translation == o)), isTrue);
      expect(t.answer(true), isTrue);
    } while (t.next());
    expect(asked, {for (final c in batch) c.id});
    expect(t.remembered, 5);
    expect(t.missed, 0);
  });

  test('a wrong answer comes back at the end; only the first try counts', () {
    final batch = deck.sublist(0, 3);
    final t = BatchTest(batch, deck, koreanPrompt: true, rng: Random(2));
    final missedId = t.current.card.id;
    expect(t.answer(false), isFalse, reason: 'first try is saved as "didn\'t know"');
    expect(t.length, 4);
    t.next();
    t.answer(true);
    t.next();
    t.answer(true);
    expect(t.next(), isTrue, reason: 'the retry is still to come');
    expect(t.current.card.id, missedId);
    expect(t.current.isRetry, isTrue);
    expect(t.answer(false), isNull, reason: 'retries are not saved');
    t.next();
    expect(t.answer(true), isNull);
    expect(t.next(), isFalse);
    expect(t.results, {missedId: false, for (final c in batch) if (c.id != missedId) c.id: true});
    expect(t.remembered, 2);
    expect(t.missed, 1);
  });

  test('translation → Korean asks the translation and offers Korean', () {
    final t = BatchTest(deck.sublist(0, 2), deck, koreanPrompt: false, rng: Random(3));
    final q = t.current;
    expect(q.prompt, q.card.translation);
    expect(q.hint, '');
    expect(q.options[q.correctIndex], q.card.korean);
  });

  test('duplicate translations are never offered as wrong options', () {
    final pool = [card(0, translation: 'eye'), card(1, translation: 'eye'), card(2, translation: 'snow')];
    final t = BatchTest([pool[0]], pool, koreanPrompt: true, rng: Random(4));
    expect(t.current.options..sort(), ['eye', 'snow']);
  });

  test('needs at least two different answers to make a test', () {
    expect(BatchTest.canTest([card(0)], koreanPrompt: true), isFalse);
    expect(BatchTest.canTest([card(0, translation: 'a'), card(1, translation: 'a')], koreanPrompt: true), isFalse);
    expect(BatchTest.canTest([card(0), card(1)], koreanPrompt: true), isTrue);
  });
}
