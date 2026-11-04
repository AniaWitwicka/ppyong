import '../models/card.dart';
import 'api_service.dart';

/// Loads every deck with [load] in parallel and joins the cards in deck order.
Future<List<CardModel>> joinDeckCards(
    List<String> deckIds, Future<List<CardModel>> Function(String deckId) load) async {
  final perDeck = await Future.wait(deckIds.map(load));
  return [for (final cards in perDeck) ...cards];
}

class CardService {
  CardService._();
  static final CardService instance = CardService._();

  final _api = ApiService.instance;

  Future<List<CardModel>> listCards(String deckId, {String scope = ''}) async {
    final path = scope.isEmpty ? '/decks/$deckId/cards' : '/decks/$deckId/cards?scope=$scope';
    final data = await _api.get(path);
    return (data as List).map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Cards of several decks, loaded in parallel and joined in deck order.
  Future<List<CardModel>> listCardsForDecks(List<String> deckIds, {String scope = ''}) =>
      joinDeckCards(deckIds, (id) => listCards(id, scope: scope));

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

  /// Records a finished game so it counts toward the streak and the group feed.
  Future<void> logPractice({
    required String deckId,
    required String mode,
    required int matched,
    required int mistakes,
  }) async {
    await _api.post('/practice', {
      'deck_id': deckId,
      'mode': mode,
      'matched': matched,
      'mistakes': mistakes,
    });
  }
}
