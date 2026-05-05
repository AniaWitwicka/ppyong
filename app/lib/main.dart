import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const PpyongApp());
}

class PpyongApp extends StatelessWidget {
  const PpyongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뿅',
      theme: AppTheme.light,
      home: AuthService.instance.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
