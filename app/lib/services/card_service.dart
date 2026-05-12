import '../models/card.dart';
import 'api_service.dart';

class CardService {
  CardService._();
  static final CardService instance = CardService._();

  final _api = ApiService.instance;

  Future<List<CardModel>> listCards(String deckId, {String scope = ''}) async {
    final path = scope.isEmpty ? '/decks/$deckId/cards' : '/decks/$deckId/cards?scope=$scope';
    final data = await _api.get(path);
    return (data as List).map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CardModel> createCard(
    String deckId, {
    required String korean,
    required String romanisation,
    required String translation,
    required String notes,
  }) async {
    final data = await _api.post('/decks/$deckId/cards', {
      'korean': korean,
      'romanisation': romanisation,
      'translation': translation,
      'notes': notes,
    });
    return CardModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CardModel> updateCard(
    String id, {
    String? korean,
    String? romanisation,
    String? translation,
    String? notes,
  }) async {
    final data = await _api.patch('/cards/$id', {
      if (korean != null) 'korean': korean,
      if (romanisation != null) 'romanisation': romanisation,
      if (translation != null) 'translation': translation,
      if (notes != null) 'notes': notes,
    });
    return CardModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCard(String id) async {
    await _api.delete('/cards/$id');
  }

  Future<void> reviewCard(String id, bool knewIt) async {
    await _api.post('/cards/$id/review', {'knew_it': knewIt});
  }
}
