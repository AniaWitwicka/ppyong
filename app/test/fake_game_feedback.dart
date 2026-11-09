import 'package:flutter/widgets.dart';
import 'package:ppyong/services/game_feedback.dart';
import 'package:provider/provider.dart';

/// Records which feedback the games asked for, plays nothing.
class FakeGameFeedback extends GameFeedback {
  FakeGameFeedback() : super(player: const SilentSoundPlayer());

  final calls = <String>[];

  @override
  void correct() => calls.add('correct');
  @override
  void wrong() => calls.add('wrong');
  @override
  void again() => calls.add('again');
  @override
  void tap() => calls.add('tap');
  @override
  void sessionComplete() => calls.add('sessionComplete');
  @override
  void batchComplete() => calls.add('batchComplete');

  /// [child] with this fake as the app's [GameFeedback].
  Widget provide(Widget child) =>
      ChangeNotifierProvider<GameFeedback>.value(value: this, child: child);
}
