import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException $statusCode: $message';
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Switch to your deployed URL for production.
  static const _baseUrl = 'http://localhost:8080';

  // Set after login, cleared on sign-out.
  String? _token;
  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) => _send('GET', path, null);
  Future<dynamic> post(String path, Map<String, dynamic> body) => _send('POST', path, body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) => _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path, null);

  Future<dynamic> _send(String method, String path, Map<String, dynamic>? body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _parseError(response));
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  String _parseError(http.Response r) {
    try {
      return (jsonDecode(r.body) as Map)['error'] as String? ??
          r.reasonPhrase ??
          'Unknown error';
    } catch (_) {
      return r.reasonPhrase ?? 'Unknown error';
    }
  }
}
