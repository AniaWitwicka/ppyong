enum CardStatus { mastered, learning, newCard }

class CardModel {
  const CardModel({
    required this.id,
    required this.korean,
    required this.romanisation,
    required this.translation,
    required this.notes,
    required this.status,
    this.dueDate,
    this.lastReviewed,
    this.intervalDays = 0,
  });

  final String id;
  final String korean;
  final String romanisation;
  final String translation;
  final String notes;
  final CardStatus status;
  final DateTime? dueDate;

  /// Last time the user answered this word; null = never studied.
  final DateTime? lastReviewed;

  /// Current review gap in days: shorter = less known.
  final int intervalDays;

  /// Never studied. Sharing a deck makes "new"-looking rows that were never
  /// reviewed; a word reset by "Again" has been reviewed, so it isn't new.
  bool get isNew => status == CardStatus.newCard && lastReviewed == null;

  factory CardModel.fromJson(Map<String, dynamic> j) => CardModel(
        id: j['id'] as String,
        korean: j['korean'] as String,
        romanisation: j['romanisation'] as String? ?? '',
        translation: j['translation'] as String,
        notes: j['notes'] as String? ?? '',
        status: _parseStatus(j['status'] as String? ?? 'new'),
        dueDate: j['due_date'] == null ? null : DateTime.tryParse(j['due_date'] as String),
        lastReviewed: j['last_reviewed'] == null
            ? null
            : DateTime.tryParse(j['last_reviewed'] as String),
        intervalDays: (j['interval_days'] as num?)?.toInt() ?? 0,
      );

  static CardStatus _parseStatus(String s) => switch (s) {
        'mastered' => CardStatus.mastered,
        'learning'  => CardStatus.learning,
        _           => CardStatus.newCard,
      };
}
