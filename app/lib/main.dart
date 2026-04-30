import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _backendUrl = 'http://localhost:8080';

void main() {
  runApp(const PpyongApp());
}

class PpyongApp extends StatelessWidget {
  const PpyongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '뿅',
      home: PingScreen(),
    );
  }
}

class PingScreen extends StatefulWidget {
  const PingScreen({super.key});

  @override
  State<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> {
  String _status = 'Press the button to ping the backend';
  bool _loading = false;

  Future<void> _ping() async {
    setState(() {
      _loading = true;
      _status = 'Pinging...';
    });

    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/ping'))
          .timeout(const Duration(seconds: 5));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() => _status = '✓ ${body['message']}');
    } catch (e) {
      setState(() => _status = '✗ $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('뿅 ppyong')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _ping,
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ping backend'),
            ),
          ],
        ),
      ),
    );
  }
}
