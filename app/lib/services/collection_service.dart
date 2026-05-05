import '../models/collection.dart';
import 'api_service.dart';

class CollectionService {
  CollectionService._();
  static final CollectionService instance = CollectionService._();

  final _api = ApiService.instance;

  Future<List<Collection>> listCollections() async {
    final data = await _api.get('/collections');
    return (data as List).map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Collection> getCollection(String id) async {
    final data = await _api.get('/collections/$id');
    return Collection.fromJson(data as Map<String, dynamic>);
  }

  Future<Collection> createCollection({
    required String name,
    required String emoji,
    required String color,
  }) async {
    final data = await _api.post('/collections', {
      'name': name,
      'emoji': emoji,
      'color': color,
    });
    return Collection.fromJson(data as Map<String, dynamic>);
  }

  Future<Collection> updateCollection(
    String id, {
    String? name,
    String? emoji,
    String? color,
  }) async {
    final data = await _api.patch('/collections/$id', {
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
    });
    return Collection.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCollection(String id) async {
    await _api.delete('/collections/$id');
  }
}
