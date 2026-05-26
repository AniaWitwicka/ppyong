class ParsedCard {
  ParsedCard({
    required this.korean,
    required this.translation,
    this.romanisation = '',
    this.notes = '',
  });

  String korean;
  String translation;
  String romanisation;
  String notes;

  factory ParsedCard.fromJson(Map<String, dynamic> j) => ParsedCard(
        korean: j['korean'] as String,
        translation: j['translation'] as String,
        romanisation: (j['romanisation'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'korean': korean,
        'translation': translation,
        'romanisation': romanisation,
        'notes': notes,
      };
}

class ImportResult {
  const ImportResult({
    required this.detectedFormat,
    required this.parsedCards,
    required this.totalCount,
  });

  final String detectedFormat;
  final List<ParsedCard> parsedCards;
  final int totalCount;

  factory ImportResult.fromJson(Map<String, dynamic> j) => ImportResult(
        detectedFormat: j['detected_format'] as String,
        parsedCards: (j['parsed_cards'] as List)
            .map((e) => ParsedCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCount: j['total_count'] as int,
      );
}
