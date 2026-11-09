import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sounds of the games. The same sound always means the same thing
/// in every game (HRHTA-103 standards).
enum FeedbackSound { correct, wrong, tap, flip, complete, batch }

/// Plays the feedback sounds. Swapped for a fake in tests.
abstract class SoundPlayer {
  /// Loads and decodes every sound once, so playing is instant later.
  Future<void> preload();

  /// Plays [sound] at [volume] (0–1). Restarts it if it's still playing —
  /// it never queues behind the previous one.
  Future<void> play(FeedbackSound sound, double volume);
}

/// [SoundPlayer] on `audioplayers`: one player per sound, loaded once and
/// replayed from memory. Files live in `assets/sounds/<name>.mp3`.
class AudioplayersSoundPlayer implements SoundPlayer {
  final Map<FeedbackSound, AudioPlayer> _players = {};
  Future<void>? _preloading;

  @override
  Future<void> preload() => _preloading ??= _load();

  Future<void> _load() async {
    await Future.wait(FeedbackSound.values.map((sound) async {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop); // keep it loaded
        await player.setSource(AssetSource('sounds/${sound.name}.mp3'));
        _players[sound] = player;
      } catch (_) {
        // Missing file or no audio: this sound stays silent.
      }
    }));
  }

  @override
  Future<void> play(FeedbackSound sound, double volume) async {
    await preload();
    final player = _players[sound];
    if (player == null) return;
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.resume();
    } catch (_) {
      // Blocked audio (no tap yet) or a broken file: stay silent.
    }
  }
}

/// A [SoundPlayer] that plays nothing.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();
  @override
  Future<void> preload() async {}
  @override
  Future<void> play(FeedbackSound sound, double volume) async {}
}

/// The one place the games give feedback: a short sound and (Android) a
/// short vibration on each answer, each switchable in Profile.
///
/// Get it with [GameFeedback.of]. Every call fails silently — feedback never
/// shows an error or blocks the game.
class GameFeedback extends ChangeNotifier {
  GameFeedback({SoundPlayer? player})
      : _player = player ?? AudioplayersSoundPlayer();

  final SoundPlayer _player;

  static const soundKey = 'feedback_sound';
  static const vibrationKey = 'feedback_vibration';
  static const volumeKey = 'feedback_volume';

  /// Where the Profile volume slider starts: the loudness the sounds were
  /// tuned at. Higher plays louder, up to each file's full level.
  static const defaultVolume = 0.7;

  /// Answer sounds a bit below normal UI level; the phone's own volume is
  /// never changed.
  static const volumes = {
    FeedbackSound.correct: 0.65,
    FeedbackSound.wrong: 0.55,
    FeedbackSound.tap: 0.35,
    FeedbackSound.flip: 0.6,
    FeedbackSound.complete: 0.7,
    FeedbackSound.batch: 0.65,
  };

  /// "Again" in Flashcards: the wrong tone, but much quieter — an honest
  /// self-rating, not a mistake.
  static const againVolume = 0.25;

  /// Gap between the two short buzzes of [wrong].
  static const wrongBuzzGap = Duration(milliseconds: 80);

  bool _sound = true;
  bool _vibration = true;
  double _volume = defaultVolume;
  bool get soundOn => _sound;
  bool get vibrationOn => _vibration;

  /// The app's sound volume, 0–1 (the Profile slider). The phone's own
  /// volume still applies on top.
  double get volume => _volume;

  /// iPhone browsers can't vibrate, so Profile hides the switch there.
  static bool get canVibrate => defaultTargetPlatform != TargetPlatform.iOS;

  /// The app's [GameFeedback], or a silent one when none is provided
  /// (e.g. a widget test that pumps a single screen).
  static GameFeedback of(BuildContext context) =>
      Provider.of<GameFeedback?>(context, listen: false) ?? _silent;
  static final _silent = GameFeedback(player: const SilentSoundPlayer())
    .._sound = false
    .._vibration = false;

  /// Reads the switches saved on this device. Both are on by default.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sound = prefs.getBool(soundKey) ?? true;
      _vibration = prefs.getBool(vibrationKey) ?? true;
      _volume = (prefs.getDouble(volumeKey) ?? defaultVolume).clamp(0.0, 1.0);
      notifyListeners();
    } catch (_) {}
  }

  /// Turning it on plays the quiet tap sound, so you hear that it works.
  Future<void> setSound(bool on) async {
    _sound = on;
    notifyListeners();
    if (on) tap();
    try {
      await (await SharedPreferences.getInstance()).setBool(soundKey, on);
    } catch (_) {}
  }

  /// Turning it on gives one light buzz, so you feel that it works.
  Future<void> setVibration(bool on) async {
    _vibration = on;
    notifyListeners();
    if (on) _haptic(HapticFeedback.lightImpact);
    try {
      await (await SharedPreferences.getInstance()).setBool(vibrationKey, on);
    } catch (_) {}
  }

  /// Moves the volume while the slider is dragged (not saved yet).
  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Slider let go: saves the volume and plays the right-answer sound at the
  /// new level, so you hear how loud it is.
  Future<void> commitVolume() async {
    _play(FeedbackSound.correct);
    try {
      await (await SharedPreferences.getInstance()).setDouble(volumeKey, _volume);
    } catch (_) {}
  }

  /// Loads the sounds. Called on the first tap anywhere in the app — browsers
  /// only allow audio after a user gesture, and nothing ever autoplays.
  Future<void> warmUp() async {
    if (!_sound) return;
    try {
      await _player.preload();
    } catch (_) {}
  }

  /// Right answer, "knew it", matched pair: ding + one light tap.
  void correct() {
    _play(FeedbackSound.correct);
    _haptic(HapticFeedback.lightImpact);
  }

  /// Wrong answer, mismatch: soft low tone + two short buzzes.
  void wrong() {
    _play(FeedbackSound.wrong);
    if (!_vibration) return;
    _haptic(HapticFeedback.mediumImpact);
    Timer(wrongBuzzGap, () => _haptic(HapticFeedback.mediumImpact));
  }

  /// "Again" / "didn't know" in Flashcards: the wrong tone, quiet, and one
  /// light tap. Softer than [wrong] so rating yourself honestly never feels
  /// like a punishment.
  void again() {
    _play(FeedbackSound.wrong, volume: againVolume);
    _haptic(HapticFeedback.lightImpact);
  }

  /// Light touch (pick a tile, the Sounds switch sample): quiet click, no
  /// vibration.
  void tap() => _play(FeedbackSound.tap);

  /// Turning a flashcard over: soft paper swish, no vibration.
  void flip() => _play(FeedbackSound.flip);

  /// End of a batch / quiz / matching round: jingle + one strong tap.
  void sessionComplete() {
    _play(FeedbackSound.complete);
    _haptic(HapticFeedback.heavyImpact);
  }

  /// A batch done with more still to come: a smaller win than [sessionComplete].
  void batchComplete() {
    _play(FeedbackSound.batch);
    _haptic(HapticFeedback.mediumImpact);
  }

  void _play(FeedbackSound sound, {double? volume}) {
    if (!_sound || _volume == 0) return;
    final level = ((volume ?? volumes[sound]!) * _volume / defaultVolume).clamp(0.0, 1.0);
    _player.play(sound, level).catchError((_) {});
  }

  void _haptic(Future<void> Function() buzz) {
    if (!_vibration) return;
    buzz().catchError((_) {});
  }
}
