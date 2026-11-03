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
}
