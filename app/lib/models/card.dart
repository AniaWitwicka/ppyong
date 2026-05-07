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
  });

  final String id;
  final String korean;
  final String romanisation;
  final String translation;
  final String notes;
  final CardStatus status;
  final DateTime? dueDate;

  factory CardModel.fromJson(Map<String, dynamic> j) => CardModel(
        id: j['id'] as String,
        korean: j['korean'] as String,
        romanisation: j['romanisation'] as String? ?? '',
        translation: j['translation'] as String,
        notes: j['notes'] as String? ?? '',
        status: _parseStatus(j['status'] as String? ?? 'new'),
        dueDate: j['due_date'] == null ? null : DateTime.tryParse(j['due_date'] as String),
      );

  static CardStatus _parseStatus(String s) => switch (s) {
        'mastered' => CardStatus.mastered,
        'learning'  => CardStatus.learning,
        _           => CardStatus.newCard,
      };
}
