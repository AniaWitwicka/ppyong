import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'teacher_service.dart';
import 'user_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'auth_token';

  /// Saved values that belong to one account, not to the device: the Resume
  /// card's deck and the matching game's best scores.
  static const _accountKeys = ['last_deck_id', 'last_deck_name'];
  static const _accountKeyPrefixes = ['match_best_'];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) ApiService.instance.setToken(token);
  }

  bool get isLoggedIn => ApiService.instance.hasToken;

  Future<UserProfile> login(String email, String password) async {
    final data = await ApiService.instance.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final token = (data as Map<String, dynamic>)['token'] as String;
    await _persist(token);
    final me = await ApiService.instance.get('/me');
    return UserProfile.fromJson(me as Map<String, dynamic>);
  }

  /// Returns true if the account was auto-activated (allowlisted email),
  /// false if it's pending approval.
  Future<bool> register(String name, String email, String password) async {
    final data = await ApiService.instance.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    final map = data as Map<String, dynamic>;
    if (map['token'] != null) {
      await _persist(map['token'] as String);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ApiService.instance.clearToken();
    await _forgetAccount(prefs);
  }

  Future<void> _persist(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await _forgetAccount(prefs);
    await prefs.setString(_tokenKey, token);
    ApiService.instance.setToken(token);
  }

  /// Drops everything kept for the previous account, so the next person who
  /// signs in on this device doesn't see their name, role or Resume card.
  Future<void> _forgetAccount(SharedPreferences prefs) async {
    UserService.instance.clearCache();
    TeacherService.instance.clearCache();
    final keys = prefs.getKeys().where((k) =>
        _accountKeys.contains(k) || _accountKeyPrefixes.any(k.startsWith));
    for (final k in keys.toList()) {
      await prefs.remove(k);
    }
  }
}
