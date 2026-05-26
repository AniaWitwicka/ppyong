import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/squiggle_background.dart';

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
      builder: (context, child) => Container(
        color: const Color(0xFFECE8E1),
        child: SquiggleBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFDF9),
                  ),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
      home: AuthService.instance.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
