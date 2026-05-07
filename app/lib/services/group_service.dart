import '../models/group.dart';
import 'api_service.dart';

class GroupService {
  GroupService._();
  static final GroupService instance = GroupService._();

  final _api = ApiService.instance;

  Future<List<GroupSummary>> listGroups() async {
    final data = await _api.get('/groups');
    return (data as List)
        .map((e) => GroupSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupSummary> createGroup({
    required String name,
    required String emoji,
    required String color,
  }) async {
    final data = await _api.post('/groups', {
      'name': name,
      'emoji': emoji,
      'color': color,
    });
    return GroupSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<GroupDetail> getGroup(String id) async {
    final data = await _api.get('/groups/$id');
    return GroupDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<GroupSummary> updateGroup(String id, {String? name, String? emoji, String? color}) async {
    final data = await _api.patch('/groups/$id', {
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
    });
    return GroupSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<void> leaveGroup(String id) => _api.post('/groups/$id/leave', {});

  Future<void> deleteGroup(String id) => _api.delete('/groups/$id');
}
