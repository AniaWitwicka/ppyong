class DeckSummary {
  const DeckSummary({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.masteredCount,
    required this.learningCount,
    required this.newCount,
  });

  final String id;
  final String name;
  final int cardCount;
  final int masteredCount;
  final int learningCount;
  final int newCount;

  double get progress =>
      cardCount == 0 ? 0 : masteredCount / cardCount;

  factory DeckSummary.fromJson(Map<String, dynamic> j) => DeckSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        cardCount: j['card_count'] as int,
        masteredCount: j['mastered_count'] as int,
        learningCount: j['learning_count'] as int,
        newCount: j['new_count'] as int,
      );
}

class DeckDetail {
  const DeckDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.collectionId,
    required this.collectionName,
    required this.cardCount,
    required this.masteredCount,
    required this.learningCount,
    required this.newCount,
  });

  final String id;
  final String name;
  final String description;
  final String collectionId;
  final String collectionName;
  final int cardCount;
  final int masteredCount;
  final int learningCount;
  final int newCount;

  factory DeckDetail.fromJson(Map<String, dynamic> j) => DeckDetail(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        collectionId: j['collection_id'] as String,
        collectionName: j['collection_name'] as String,
        cardCount: j['card_count'] as int,
        masteredCount: j['mastered_count'] as int,
        learningCount: j['learning_count'] as int,
        newCount: j['new_count'] as int,
      );
}
