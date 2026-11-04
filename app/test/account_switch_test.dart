import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ppyong/services/auth_service.dart';
import 'package:ppyong/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> profile(String id, String name, String role) => {
      'id': id,
      'name': name,
      'email': '$id@ppyong.test',
      'role': role,
      'initials': name[0],
      'streak': 0,
      'best_streak': 0,
      'last_active': '2026-11-04T00:00:00Z',
    };

/// A fake backend where the token says who is signed in.
MockClient fakeBackend() {
  final users = {
    'teacher@ppyong.test': profile('teacher', 'Tina', 'teacher'),
    'learner@ppyong.test': profile('learner', 'Lena', 'learner'),
  };
  return MockClient((req) async {
    if (req.url.path == '/auth/login') {
      final email = (jsonDecode(req.body) as Map)['email'] as String;
      return http.Response(jsonEncode({'token': email}), 200);
    }
    if (req.url.path == '/me') {
      final token = req.headers['Authorization']!.replaceFirst('Bearer ', '');
      return http.Response(jsonEncode(users[token]), 200);
    }
    return http.Response('not found', 404);
  });
}

void main() {
  test('signing in as someone else shows their profile, not the previous one', () async {
    SharedPreferences.setMockInitialValues({});
    await http.runWithClient(() async {
      await AuthService.instance.login('teacher@ppyong.test', 'pw');
      expect((await UserService.instance.getMe()).name, 'Tina');

      await AuthService.instance.logout();
      expect(UserService.instance.cachedProfile, isNull);

      await AuthService.instance.login('learner@ppyong.test', 'pw');
      final me = await UserService.instance.getMe();
      expect(me.name, 'Lena');
      expect(me.role, 'learner');
    }, fakeBackend);
  });

  test('sign-out forgets the Resume card and best scores, keeps device settings', () async {
    SharedPreferences.setMockInitialValues({
      'last_deck_id': 'd1',
      'last_deck_name': 'Jedzenie',
      'match_best_d1_60s': 7,
      'study_session_size': 15,
      'activeRole_teacher': 'learner',
    });
    await AuthService.instance.logout();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('last_deck_id'), isNull);
    expect(prefs.getString('last_deck_name'), isNull);
    expect(prefs.getInt('match_best_d1_60s'), isNull);
    expect(prefs.getInt('study_session_size'), 15);
    expect(prefs.getString('activeRole_teacher'), 'learner');
  });
}
