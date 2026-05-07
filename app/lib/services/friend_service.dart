import '../models/friend.dart';
import '../models/user.dart';
import 'api_service.dart';

class FriendService {
  FriendService._();
  static final FriendService instance = FriendService._();

  final _api = ApiService.instance;

  Future<List<Friend>> listFriends() async {
    final data = await _api.get('/friends');
    return (data as List)
        .map((e) => Friend.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserSummary>> searchUsers(String query) async {
    final data = await _api.get('/users/search?q=${Uri.encodeQueryComponent(query)}');
    return (data as List)
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendFriendRequest(String userId) =>
      _api.post('/friends/request', {'user_id': userId});

  Future<List<Friend>> listPendingRequests() async {
    final data = await _api.get('/friends/requests');
    return (data as List)
        .map((e) => Friend.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptFriendRequest(String friendshipId) =>
      _api.post('/friends/$friendshipId/accept', {});

  Future<void> declineFriendRequest(String friendshipId) =>
      _api.post('/friends/$friendshipId/decline', {});
}
