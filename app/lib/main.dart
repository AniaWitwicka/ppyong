import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PpyongApp());
}

class PpyongApp extends StatelessWidget {
  const PpyongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뿅',
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
