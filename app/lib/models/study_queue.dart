import 'card.dart';

/// Splits a deck into short study sessions.
///
/// Cards are ordered once when the queue is built — due reviews first, then
/// new words, then words still being learned, then mastered ones — keeping
/// deck order inside each group. Sessions are consecutive slices of that
/// order, so "next session" never repeats a word from this sitting.
class StudyQueue {
  StudyQueue(List<CardModel> cards, {required this.sessionSize, DateTime? today})
      : assert(sessionSize > 0),
        _ordered = orderForStudy(cards, today ?? DateTime.now());

  /// Words per session. Use a value ≥ the deck size for "All".
  final int sessionSize;
  final List<CardModel> _ordered;
  int _start = 0;

  /// Session sizes offered on the setup screen; 0 means the whole deck.
  static const sizes = [10, 15, 20, 0];
  static const defaultSize = 20;

  /// Saved choice, shared by flashcards and Multiple choice.
  static const sizePrefKey = 'study_session_size';

  int get totalCount => _ordered.length;

  /// Cards in the current session.
  List<CardModel> get session =>
      _ordered.sublist(_start, (_start + sessionSize).clamp(0, _ordered.length));

  /// Cards after the current session.
  int get remainingAfterSession =>
      (_ordered.length - _start - sessionSize).clamp(0, _ordered.length);

  bool get hasNextSession => remainingAfterSession > 0;

  /// Size of the session [nextSession] would start.
  int get nextSessionSize => remainingAfterSession.clamp(0, sessionSize);

  /// 1-based number of the current session, e.g. "session 2 of 4".
  int get sessionNumber => _start ~/ sessionSize + 1;
  int get sessionCount => (_ordered.length / sessionSize).ceil();

  void nextSession() {
    if (hasNextSession) _start += sessionSize;
  }

  /// Due reviews → new → learning (not due yet) → mastered (not due yet),
  /// keeping the incoming (deck) order inside each group.
  static List<CardModel> orderForStudy(List<CardModel> cards, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    int rank(CardModel c) {
      if (c.status == CardStatus.newCard) return 1;
      final due = c.dueDate;
      if (due != null && !DateTime(due.year, due.month, due.day).isAfter(day)) return 0;
      return c.status == CardStatus.learning ? 2 : 3;
    }

    final indexed = [for (var i = 0; i < cards.length; i++) (i, cards[i])];
    indexed.sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}
