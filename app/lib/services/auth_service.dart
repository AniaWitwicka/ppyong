import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'auth_token';

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
  }

  Future<void> _persist(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiService.instance.setToken(token);
  }
}
