import '../models/import.dart';
import 'api_service.dart';

class ImportService {
  ImportService._();
  static final ImportService instance = ImportService._();

  Future<ImportResult> previewPaste(String rawText) async {
    final data = await ApiService.instance.post('/import/preview', {'raw_text': rawText});
    return ImportResult.fromJson(data as Map<String, dynamic>);
  }

  Future<ImportResult> previewCsv(List<int> bytes, String filename) async {
    final data = await ApiService.instance.postMultipart('/import/preview', bytes, filename);
    return ImportResult.fromJson(data as Map<String, dynamic>);
  }

  Future<int> bulkCreateCards(String deckId, List<ParsedCard> cards) async {
    final data = await ApiService.instance.post(
      '/decks/$deckId/cards/bulk',
      {'cards': cards.map((c) => c.toJson()).toList()},
    );
    return (data as Map<String, dynamic>)['created'] as int;
  }
}
