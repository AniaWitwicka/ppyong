import '../models/teacher.dart';
import 'api_service.dart';

class TeacherService {
  TeacherService._();
  static final TeacherService instance = TeacherService._();

  TeacherDashboard? _dashboardCache;
  TeacherDashboard? get cachedDashboard => _dashboardCache;

  Future<TeacherDashboard> getDashboard({bool refresh = false}) async {
    if (!refresh && _dashboardCache != null) return _dashboardCache!;
    final data = await ApiService.instance.get('/teacher/dashboard');
    _dashboardCache = TeacherDashboard.fromJson(data as Map<String, dynamic>);
    return _dashboardCache!;
  }

  void prefetch() => getDashboard();

  Future<List<StudentRosterItem>> getGroupStudents(String groupId) async {
    final data = await ApiService.instance.get('/groups/$groupId/students');
    return (data as List).map((e) => StudentRosterItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ActivityEvent>> getGroupActivity(String groupId) async {
    final data = await ApiService.instance.get('/groups/$groupId/activity');
    return (data as List).map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
