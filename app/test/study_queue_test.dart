import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/models/card.dart';
import 'package:ppyong/models/study_queue.dart';

final today = DateTime(2026, 11, 3, 15, 30);

CardModel card(String id, CardStatus status, {DateTime? due}) => CardModel(
      id: id,
      korean: id,
      romanisation: '',
      translation: id,
      notes: '',
      status: status,
      dueDate: due,
    );

List<CardModel> newCards(int n) =>
    [for (var i = 0; i < n; i++) card('n$i', CardStatus.newCard)];

List<String> ids(List<CardModel> cards) => [for (final c in cards) c.id];

void main() {
  test('orders due → new → learning → mastered, keeping deck order in each group', () {
    final cards = [
      card('mastered', CardStatus.mastered, due: DateTime(2026, 11, 20)),
      card('new1', CardStatus.newCard),
      card('learning', CardStatus.learning, due: DateTime(2026, 11, 4)),
      card('dueLearning', CardStatus.learning, due: DateTime(2026, 11, 3)),
      card('new2', CardStatus.newCard),
      card('overdueMastered', CardStatus.mastered, due: DateTime(2026, 10, 30)),
    ];
    expect(ids(StudyQueue.orderForStudy(cards, today)),
        ['dueLearning', 'overdueMastered', 'new1', 'new2', 'learning', 'mastered']);
  });

  test('new cards shared with a due date of today still count as new', () {
    // Shared decks create srs rows with repetitions 0 and due today; the API
    // reports them as "new", and they should not jump ahead as reviews.
    final cards = [
      card('a', CardStatus.newCard, due: DateTime(2026, 11, 3)),
      card('b', CardStatus.learning, due: DateTime(2026, 11, 2)),
    ];
    expect(ids(StudyQueue.orderForStudy(cards, today)), ['b', 'a']);
  });

  test('splits a 61-card deck into sessions of 20 without repeats', () {
    final q = StudyQueue(newCards(61), sessionSize: 20, today: today);
    final seen = <String>[];
    final sizes = <int>[];
    while (true) {
      sizes.add(q.session.length);
      seen.addAll(ids(q.session));
      if (!q.hasNextSession) break;
      expect(q.nextSessionSize, q.remainingAfterSession.clamp(0, 20));
      q.nextSession();
    }
    expect(sizes, [20, 20, 20, 1]);
    expect(seen.toSet().length, 61);
    expect(q.sessionCount, 4);
    expect(q.sessionNumber, 4);
  });

  test('remaining counts and next session size', () {
    final q = StudyQueue(newCards(25), sessionSize: 10, today: today);
    expect(q.remainingAfterSession, 15);
    expect(q.nextSessionSize, 10);
    q.nextSession();
    expect(q.remainingAfterSession, 5);
    expect(q.nextSessionSize, 5);
    q.nextSession();
    expect(q.session, hasLength(5));
    expect(q.hasNextSession, isFalse);
    q.nextSession(); // no-op at the end
    expect(q.session, hasLength(5));
  });

  test('a session size bigger than the deck is the whole deck', () {
    final q = StudyQueue(newCards(7), sessionSize: 1000, today: today);
    expect(q.session, hasLength(7));
    expect(q.hasNextSession, isFalse);
    expect(q.sessionCount, 1);
  });

  test('least known first: missed, due, new, then shortest gap', () {
    final cards = [
      seen('mastered16', CardStatus.mastered, due: DateTime(2026, 11, 19), last: DateTime(2026, 11, 3), interval: 16),
      card('new', CardStatus.newCard),
      seen('learning6', CardStatus.learning, due: DateTime(2026, 11, 9), last: DateTime(2026, 11, 3), interval: 6),
      seen('learning1', CardStatus.learning, due: DateTime(2026, 11, 4), last: DateTime(2026, 11, 3), interval: 1),
      seen('due', CardStatus.learning, due: DateTime(2026, 11, 3), last: DateTime(2026, 11, 2), interval: 1),
      // "Again" today: reset to 0 repetitions (API says "new"), due tomorrow.
      seen('missed', CardStatus.newCard, due: DateTime(2026, 11, 4), last: DateTime(2026, 11, 3, 14), interval: 1),
    ];
    expect(ids(StudyQueue.orderForStudy(cards, today)),
        ['missed', 'due', 'new', 'learning1', 'learning6', 'mastered16']);
  });

  test('a new sitting starts with other words: the ones just studied move back', () {
    // Deck fully studied, nothing due: ten 1-day words seen yesterday, and
    // the first five of them practised again a minute ago.
    final yesterday = DateTime(2026, 11, 2, 18);
    final justNow = DateTime(2026, 11, 3, 15, 29);
    final cards = [
      for (var i = 0; i < 10; i++)
        seen('w$i', CardStatus.learning,
            due: DateTime(2026, 11, 4), last: i < 5 ? justNow : yesterday),
    ];
    final next = StudyQueue(cards, sessionSize: 5, today: today).session;
    expect(ids(next), ['w5', 'w6', 'w7', 'w8', 'w9']);
  });

  test('last_reviewed and interval_days come from the API', () {
    final c = CardModel.fromJson({
      'id': 'c1', 'korean': 'k', 'translation': 't', 'status': 'learning',
      'due_date': '2026-11-05T00:00:00Z',
      'last_reviewed': '2026-11-04T16:15:53.015695+01:00',
      'interval_days': 6,
    });
    expect(c.lastReviewed, isNotNull);
    expect(c.intervalDays, 6);
    expect(c.isNew, isFalse);
    final missed = CardModel.fromJson({
      'id': 'c2', 'korean': 'k', 'translation': 't', 'status': 'new',
      'due_date': '2026-11-05T00:00:00Z', 'last_reviewed': '2026-11-04T10:00:00Z',
    });
    expect(missed.isNew, isFalse, reason: 'reset by Again, not a new word');
    final shared = CardModel.fromJson({
      'id': 'c3', 'korean': 'k', 'translation': 't', 'status': 'new',
      'due_date': '2026-11-04T00:00:00Z', 'last_reviewed': null,
    });
    expect(shared.isNew, isTrue);
  });

}

CardModel seen(String id, CardStatus status,
        {required DateTime due, required DateTime last, int interval = 1}) =>
    CardModel(
      id: id, korean: id, romanisation: '', translation: id, notes: '',
      status: status, dueDate: due, lastReviewed: last, intervalDays: interval,
    );
