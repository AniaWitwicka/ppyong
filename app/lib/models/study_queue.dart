import 'card.dart';

/// Splits a deck into short study sessions.
///
/// Cards are ordered once when the queue is built, least known first (see
/// [orderForStudy]). Sessions are consecutive slices of that order, so "next
/// session" never repeats a word from this sitting, and a new sitting starts
/// with other words, since the ones just studied move back (HRHTA-115).
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

  /// Least known first:
  /// 1. missed words ("Again", not due yet),
  /// 2. due reviews,
  /// 3. new words,
  /// 4. the rest: learning before mastered, shortest review gap first.
  /// Inside a group, words not studied today first, then shorter gap, then
  /// the word seen longest ago, then deck order. Studying a word moves it
  /// back in its group, so sessions rotate instead of showing the same words
  /// again — also on the same day.
  static List<CardModel> orderForStudy(List<CardModel> cards, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    int group(CardModel c) {
      if (c.isNew) return 2;
      final due = c.dueDate;
      if (due != null && !DateTime(due.year, due.month, due.day).isAfter(day)) return 1;
      if (c.status == CardStatus.newCard) return 0; // reviewed, reset by "Again"
      return c.status == CardStatus.learning ? 3 : 4;
    }

    int byLastSeen(CardModel a, CardModel b) {
      final x = a.lastReviewed, y = b.lastReviewed;
      if (x == null || y == null) return (x == null ? 0 : 1) - (y == null ? 0 : 1);
      return x.compareTo(y);
    }

    // Studied today (e.g. this morning's batch and its quiz): to the back of
    // its group. A same-day "knew it" doesn't grow the gap (HRHTA-115), so
    // without this "shortest gap first" brought the same words straight back.
    bool studiedToday(CardModel c) {
      final seen = c.lastReviewed?.toLocal();
      return seen != null && !DateTime(seen.year, seen.month, seen.day).isBefore(day);
    }

    final indexed = [for (var i = 0; i < cards.length; i++) (i, cards[i], group(cards[i]))];
    indexed.sort((a, b) {
      var r = a.$3.compareTo(b.$3);
      if (r != 0) return r;
      if (a.$3 != 2) {
        r = (studiedToday(a.$2) ? 1 : 0).compareTo(studiedToday(b.$2) ? 1 : 0);
        if (r != 0) return r;
        r = a.$2.intervalDays.compareTo(b.$2.intervalDays);
        if (r != 0) return r;
        r = byLastSeen(a.$2, b.$2);
        if (r != 0) return r;
      }
      return a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}
