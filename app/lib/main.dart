import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation.dart';
import 'services/auth_service.dart';
import 'services/game_feedback.dart';
import 'theme/app_theme.dart';
import 'theme/korean_font.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/squiggle_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Korean font before the first frame, so Hangul never shows as boxes.
  // Downloads alongside sign-in (preloaded in index.html), max 4 s.
  final feedback = GameFeedback();
  await Future.wait(
      [AuthService.instance.init(), loadKoreanFont(), feedback.load()]);
  runApp(ChangeNotifierProvider.value(
    value: feedback,
    child: const PpyongApp(),
  ));
}

class PpyongApp extends StatefulWidget {
  const PpyongApp({super.key});

  @override
  State<PpyongApp> createState() => _PpyongAppState();
}

class _PpyongAppState extends State<PpyongApp> {
  bool _warmedUp = false;

  /// Game sounds load on the first tap anywhere: browsers block audio
  /// until then, and nothing should play or load on screen open.
  void _warmUpFeedback(PointerDownEvent _) {
    if (_warmedUp) return;
    _warmedUp = true;
    GameFeedback.of(context).warmUp();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _warmUpFeedback,
      child: _app(),
    );
  }

  Widget _app() {
    return MaterialApp(
      title: '뿅',
      theme: AppTheme.light,
      navigatorObservers: [appRouteObserver],
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
