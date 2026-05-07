class WeakCard {
  const WeakCard({
    required this.id,
    required this.korean,
    required this.romanisation,
    required this.translation,
    required this.notes,
    required this.deckId,
    required this.deckName,
    required this.collectionName,
    required this.easeFactor,
    required this.intervalDays,
  });

  final String id;
  final String korean;
  final String romanisation;
  final String translation;
  final String notes;
  final String deckId;
  final String deckName;
  final String collectionName;
  final double easeFactor;
  final int intervalDays;

  factory WeakCard.fromJson(Map<String, dynamic> j) => WeakCard(
        id: j['id'] as String,
        korean: j['korean'] as String,
        romanisation: j['romanisation'] as String? ?? '',
        translation: j['translation'] as String,
        notes: j['notes'] as String? ?? '',
        deckId: j['deck_id'] as String,
        deckName: j['deck_name'] as String,
        collectionName: j['collection_name'] as String,
        easeFactor: (j['ease_factor'] as num).toDouble(),
        intervalDays: j['interval_days'] as int,
      );
}
