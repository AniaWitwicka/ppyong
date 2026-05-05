import '../models/deck.dart';
import 'api_service.dart';

class DeckService {
  DeckService._();
  static final DeckService instance = DeckService._();

  final _api = ApiService.instance;

  Future<List<DeckSummary>> listDecks(String collectionId) async {
    final data = await _api.get('/collections/$collectionId/decks');
    return (data as List).map((e) => DeckSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DeckDetail> getDeck(String id) async {
    final data = await _api.get('/decks/$id');
    return DeckDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<DeckSummary> createDeck(String collectionId, {required String name, String description = ''}) async {
    final data = await _api.post('/collections/$collectionId/decks', {
      'name': name,
      'description': description,
    });
    return DeckSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<DeckDetail> updateDeck(String id, {String? name, String? description, String? collectionId}) async {
    final data = await _api.patch('/decks/$id', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (collectionId != null) 'collection_id': collectionId,
    });
    return DeckDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteDeck(String id) async {
    await _api.delete('/decks/$id');
  }

  Future<void> shareDeck(String id, List<String> memberIds) async {
    await _api.post('/decks/$id/share', {'member_ids': memberIds});
  }
}
