import '../models/user.dart';
import '../models/weak_card.dart';
import 'api_service.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _api = ApiService.instance;

  UserProfile? _profileCache;
  UserProfile? get cachedProfile => _profileCache;

  Future<UserProfile> getMe({bool refresh = false}) async {
    if (!refresh && _profileCache != null) return _profileCache!;
    final data = await _api.get('/me');
    _profileCache = UserProfile.fromJson(data as Map<String, dynamic>);
    return _profileCache!;
  }

  Future<UserStats> getMyStats() async {
    final data = await _api.get('/me/stats');
    return UserStats.fromJson(data as Map<String, dynamic>);
  }

  Future<UserSettings> getMySettings() async {
    final data = await _api.get('/me/settings');
    return UserSettings.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({String? name, String? email}) async {
    final data = await _api.patch('/me', {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    });
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<WeakCard>> getWeakCards() async {
    final data = await _api.get('/me/weak-words');
    return (data as List).map((e) => WeakCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserSummary>> listUsers() async {
    final data = await _api.get('/users');
    return (data as List).map((e) => UserSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserSettings> updateSettings({
    bool? notificationsEnabled,
    String? studyReminderTime,
  }) async {
    final data = await _api.patch('/me/settings', {
      if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
      if (studyReminderTime != null) 'study_reminder_time': studyReminderTime,
    });
    return UserSettings.fromJson(data as Map<String, dynamic>);
  }
}
