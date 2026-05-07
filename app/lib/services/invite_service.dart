import '../models/invite.dart';
import 'api_service.dart';

class InviteService {
  InviteService._();
  static final InviteService instance = InviteService._();

  final _api = ApiService.instance;

  Future<InviteList> listInvites() async {
    final data = await _api.get('/invites');
    return InviteList.fromJson(data as Map<String, dynamic>);
  }

  Future<Invite> sendInvite(String groupId, {String? email, String? userId}) async {
    assert(email != null || userId != null);
    final data = await _api.post('/groups/$groupId/invite', {
      if (email != null) 'email': email,
      if (userId != null) 'user_id': userId,
    });
    return Invite.fromJson(data as Map<String, dynamic>);
  }

  Future<void> acceptInvite(String inviteId) =>
      _api.post('/invites/$inviteId/accept', {});

  Future<void> declineInvite(String inviteId) =>
      _api.post('/invites/$inviteId/decline', {});

  Future<int> pendingCount() async {
    final data = await _api.get('/invites/pending-count');
    return (data as Map<String, dynamic>)['count'] as int;
  }
}
