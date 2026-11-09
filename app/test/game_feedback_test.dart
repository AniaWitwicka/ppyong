import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ppyong/screens/profile_screen.dart';
import 'package:ppyong/services/game_feedback.dart';
import 'package:ppyong/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSoundPlayer implements SoundPlayer {
  final played = <FeedbackSound>[];
  final volumes = <double>[];
  int preloads = 0;
  @override
  Future<void> preload() async => preloads++;
  @override
  Future<void> play(FeedbackSound sound, double volume) async {
    played.add(sound);
    volumes.add(volume);
  }
}

class ThrowingSoundPlayer implements SoundPlayer {
  @override
  Future<void> preload() async => throw Exception('no audio');
  @override
  Future<void> play(FeedbackSound sound, double volume) async =>
      throw Exception('blocked');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Haptic calls the app made, e.g. 'HapticFeedbackType.lightImpact'.
  late List<String> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<(GameFeedback, FakeSoundPlayer)> make(
      [Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final player = FakeSoundPlayer();
    final feedback = GameFeedback(player: player);
    await feedback.load();
    return (feedback, player);
  }

  test('both switches are on by default', () async {
    final (feedback, _) = await make();
    expect(feedback.soundOn, isTrue);
    expect(feedback.vibrationOn, isTrue);
  });

  test('a finished batch has its own jingle, not the right-answer pop', () async {
    final (feedback, player) = await make();
    feedback.correct();
    feedback.batchComplete();
    feedback.sessionComplete();
    await Future<void>.delayed(Duration.zero);
    expect(player.played,
        [FeedbackSound.correct, FeedbackSound.batch, FeedbackSound.complete]);
    expect(haptics.last, 'HapticFeedbackType.heavyImpact');
    expect(haptics[1], 'HapticFeedbackType.mediumImpact');
  });

  test('each call plays its sound and its vibration', () async {
    final (feedback, player) = await make();
    feedback.correct();
    feedback.tap();
    feedback.sessionComplete();
    await Future<void>.delayed(Duration.zero);
    expect(player.played,
        [FeedbackSound.correct, FeedbackSound.tap, FeedbackSound.complete]);
    // tap() never vibrates.
    expect(haptics,
        ['HapticFeedbackType.lightImpact', 'HapticFeedbackType.heavyImpact']);
  });

  test('wrong() is a soft tone plus two short buzzes', () async {
    final (feedback, player) = await make();
    feedback.wrong();
    await Future<void>.delayed(Duration.zero);
    expect(player.played, [FeedbackSound.wrong]);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
    await Future<void>.delayed(
        GameFeedback.wrongBuzzGap + const Duration(milliseconds: 20));
    expect(haptics,
        ['HapticFeedbackType.mediumImpact', 'HapticFeedbackType.mediumImpact']);
  });

  test('again() is a much quieter wrong tone with one light tap', () async {
    final (feedback, player) = await make();
    feedback.wrong();
    await Future<void>.delayed(
        GameFeedback.wrongBuzzGap + const Duration(milliseconds: 20));
    haptics.clear();
    feedback.again();
    await Future<void>.delayed(
        GameFeedback.wrongBuzzGap + const Duration(milliseconds: 20));
    expect(player.played, [FeedbackSound.wrong, FeedbackSound.wrong]);
    expect(player.volumes.last, lessThan(player.volumes.first / 2));
    expect(haptics, ['HapticFeedbackType.lightImpact'], reason: 'one light tap only');
  });

  test('flip() is the card swish, with no vibration', () async {
    final (feedback, player) = await make();
    feedback.flip();
    await Future<void>.delayed(Duration.zero);
    expect(player.played, [FeedbackSound.flip]);
    expect(haptics, isEmpty);
  });

  test('volume: the default plays as tuned, louder and quieter scale it, 0 is silent',
      () async {
    final (feedback, player) = await make();
    expect(feedback.volume, GameFeedback.defaultVolume);
    feedback.correct();
    feedback.setVolume(1.0);
    feedback.correct();
    feedback.sessionComplete();
    feedback.setVolume(0.35);
    feedback.correct();
    feedback.setVolume(0);
    feedback.correct();
    await Future<void>.delayed(Duration.zero);
    final base = GameFeedback.volumes[FeedbackSound.correct]!;
    expect(player.volumes[0], closeTo(base, 1e-9), reason: 'default = as tuned');
    expect(player.volumes[1], greaterThan(base));
    expect(player.volumes[2], 1.0, reason: 'never above full level');
    expect(player.volumes[3], closeTo(base / 2, 1e-9));
    expect(player.played, hasLength(4), reason: 'volume 0 plays nothing');
    expect(haptics, hasLength(5), reason: 'vibration does not depend on volume');
  });

  test('letting go of the slider saves the volume and plays a sample', () async {
    final (feedback, player) = await make();
    feedback.setVolume(0.4);
    await feedback.commitVolume();
    expect(player.played, [FeedbackSound.correct]);
    expect(haptics, isEmpty, reason: 'the sample is sound only');
    final restarted = GameFeedback(player: FakeSoundPlayer());
    await restarted.load();
    expect(restarted.volume, 0.4);
  });

  test('with Sounds off nothing plays, vibration still works', () async {
    final (feedback, player) = await make({GameFeedback.soundKey: false});
    feedback.correct();
    feedback.wrong();
    await feedback.warmUp();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(player.played, isEmpty);
    expect(player.preloads, 0);
    expect(haptics, isNotEmpty);
  });

  test('with Vibration off there are no haptic calls, sound still plays',
      () async {
    final (feedback, player) = await make({GameFeedback.vibrationKey: false});
    feedback.correct();
    feedback.wrong();
    feedback.sessionComplete();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(haptics, isEmpty);
    expect(player.played, hasLength(3));
  });

  test('switching on gives a sample: tap sound / light buzz', () async {
    final (feedback, player) = await make(
        {GameFeedback.soundKey: false, GameFeedback.vibrationKey: false});
    await feedback.setSound(true);
    await feedback.setVibration(true);
    expect(player.played, [FeedbackSound.tap]);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await feedback.setSound(false);
    await feedback.setVibration(false);
    expect(player.played, hasLength(1));
    expect(haptics, hasLength(1));
  });

  test('switches are saved on the device', () async {
    final (feedback, _) = await make();
    await feedback.setSound(false);
    await feedback.setVibration(false);
    final again = GameFeedback(player: FakeSoundPlayer());
    await again.load();
    expect(again.soundOn, isFalse);
    expect(again.vibrationOn, isFalse);
  });

  test('broken audio fails silently', () async {
    SharedPreferences.setMockInitialValues({});
    final feedback = GameFeedback(player: ThrowingSoundPlayer());
    await feedback.warmUp();
    feedback.correct();
    feedback.wrong();
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  testWidgets('of() without a provider gives a silent one', (tester) async {
    // Screens pumped alone in tests get a no-op instead of a crash.
    late GameFeedback feedback;
    await tester.pumpWidget(_Probe((c) => feedback = GameFeedback.of(c)));
    expect(feedback.soundOn, isFalse);
    expect(feedback.vibrationOn, isFalse);
    feedback.wrong();
    await tester.pump(const Duration(milliseconds: 100));
    expect(haptics, isEmpty);
  });

  group('Profile', () {
    MockClient backend() => MockClient((req) async {
          switch (req.url.path) {
            case '/me':
              return http.Response(
                  jsonEncode({
                    'id': 'u1',
                    'name': 'Lena',
                    'email': 'lena@ppyong.test',
                    'role': 'learner',
                    'initials': 'L',
                    'streak': 1,
                    'best_streak': 2,
                    'last_active': '2026-11-09T00:00:00Z',
                  }),
                  200);
            case '/me/stats':
              return http.Response(
                  jsonEncode({
                    'mastered_count': 1,
                    'learning_count': 2,
                    'session_count': 3,
                    'accuracy_percent': 80,
                    'weekly_activity': List.filled(7, false),
                  }),
                  200);
          }
          return http.Response('not found', 404);
        });

    Future<void> openProfile(WidgetTester tester, GameFeedback feedback) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await http.runWithClient(() async {
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: feedback,
          child: const MaterialApp(home: ProfileScreen()),
        ));
        await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50)));
      }, backend);
      await tester.pumpAndSettle();
    }

    Switch switchOf(WidgetTester tester, String key) =>
        tester.widget<Switch>(find.descendant(
            of: find.byKey(ValueKey(key)), matching: find.byType(Switch)));

    testWidgets('Sounds and Vibration switches change and are remembered',
        (tester) async {
      UserService.instance.clearCache();
      SharedPreferences.setMockInitialValues({});
      final feedback = GameFeedback(player: FakeSoundPlayer());
      await tester.runAsync(feedback.load);
      await openProfile(tester, feedback);

      expect(find.text('Sounds'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);
      expect(switchOf(tester, 'sound-switch').value, isTrue);
      expect(switchOf(tester, 'vibration-switch').value, isTrue);

      // The volume slider sits under Sounds; dragging it left lowers and saves it.
      final slider = find.byKey(const ValueKey('volume-slider'));
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(feedback.volume, lessThan(GameFeedback.defaultVolume));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble(GameFeedback.volumeKey), feedback.volume);

      await tester.tap(find.byKey(const ValueKey('sound-switch')));
      await tester.tap(find.text('Vibration')); // the whole row toggles
      await tester.pumpAndSettle();
      expect(switchOf(tester, 'sound-switch').value, isFalse);
      expect(switchOf(tester, 'vibration-switch').value, isFalse);
      expect(find.byKey(const ValueKey('volume-slider')), findsNothing,
          reason: 'no slider while Sounds is off');

      // "Restart": a fresh service reads what was saved.
      final restarted = GameFeedback(player: FakeSoundPlayer());
      await tester.runAsync(restarted.load);
      expect(restarted.soundOn, isFalse);
      expect(restarted.vibrationOn, isFalse);
    });

    testWidgets('no Vibration switch on iPhone', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      UserService.instance.clearCache();
      SharedPreferences.setMockInitialValues({});
      final feedback = GameFeedback(player: FakeSoundPlayer());
      await openProfile(tester, feedback);
      expect(find.text('Sounds'), findsOneWidget);
      expect(find.text('Vibration'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);
  final void Function(BuildContext) onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox();
  }
}
