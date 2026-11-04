import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/screens/login_screen.dart';
import 'package:ppyong/services/api_service.dart';

void main() {
  test('duplicate email says the account exists', () {
    expect(registerErrorMessage(const ApiException(409, 'email already in use')).$1,
        'This email already has an account');
  });

  test('invite-only says registration is by invitation', () {
    expect(registerErrorMessage(const ApiException(403, 'registration is by invitation only')).$1,
        'Registration is by invitation');
  });

  test('rate limit asks to wait', () {
    expect(registerErrorMessage(const ApiException(429, 'too many requests, slow down')),
        ('Too many tries', 'Wait a minute and try again'));
  });

  test('bad input shows the server message', () {
    expect(registerErrorMessage(const ApiException(400, 'password must be at least 8 characters')).$2,
        'Password must be at least 8 characters');
  });

  test('server error and no connection have their own messages', () {
    expect(registerErrorMessage(const ApiException(500, 'internal server error')).$2,
        contains('on our side'));
    expect(registerErrorMessage(Exception('XMLHttpRequest error')).$1, "Couldn't reach Ppyong");
  });
}
