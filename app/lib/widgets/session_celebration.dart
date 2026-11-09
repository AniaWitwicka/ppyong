import 'dart:math';

import 'package:flutter/material.dart';

import '../services/game_feedback.dart';
import '../theme/app_theme.dart';

/// Wraps a game's completion screen: plays the "done" feedback once when the
/// screen opens and throws a short burst of confetti behind [child].
///
/// [big] is the end of the whole quiz/session (complete jingle, full
/// confetti); otherwise it's a batch with more to come (smaller burst).
/// The same celebration plays whatever the score — finishing is the win.
///
/// The confetti never catches taps and is skipped when the system asks for
/// reduced motion ([MediaQuery.disableAnimations]); sound and text stay.
class SessionCelebration extends StatefulWidget {
  const SessionCelebration({super.key, required this.big, required this.child});

  final bool big;
  final Widget child;

  static const confettiKey = ValueKey('celebration-confetti');
  static const duration = Duration(milliseconds: 1400);

  @override
  State<SessionCelebration> createState() => _SessionCelebrationState();
}

class _SessionCelebrationState extends State<SessionCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: SessionCelebration.duration);
    _pieces = _Piece.burst(Random(), widget.big ? 70 : 28);
    // initState runs once per screen, so rebuilds never replay it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final feedback = GameFeedback.of(context);
      widget.big ? feedback.sessionComplete() : feedback.batchComplete();
      if (!MediaQuery.disableAnimationsOf(context)) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        if (!reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => _ctrl.isAnimating
                    ? CustomPaint(
                        key: SessionCelebration.confettiKey,
                        painter: _ConfettiPainter(_pieces, _ctrl.value),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

const _colors = [
  AppColors.sunnyYellow,
  AppColors.bubblegum,
  AppColors.periwinkle,
  AppColors.forestGreen,
];

/// One bit of confetti. Velocities are in screen-widths per second, so the
/// burst looks the same on a phone and a laptop.
class _Piece {
  _Piece(this.vx, this.vy, this.spin, this.size, this.color, this.round);

  final double vx, vy, spin, size;
  final Color color;
  final bool round;

  static List<_Piece> burst(Random rng, int count) => List.generate(count, (i) {
        // Fan upwards from the trophy, mostly up and out.
        final angle = -pi / 2 + (rng.nextDouble() - 0.5) * pi * 0.9;
        final speed = 0.55 + rng.nextDouble() * 0.6;
        return _Piece(
          cos(angle) * speed,
          sin(angle) * speed,
          (rng.nextDouble() - 0.5) * 12,
          5 + rng.nextDouble() * 5,
          _colors[i % _colors.length],
          rng.nextBool(),
        );
      });
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;

  /// 0..1 through the animation.
  final double t;

  static const _gravity = 1.6; // screen-widths / s²

  @override
  void paint(Canvas canvas, Size size) {
    final secs = t * SessionCelebration.duration.inMilliseconds / 1000;
    final unit = min(size.width, 480.0);
    // Starts where the trophy sits on the completion screens.
    final origin = Offset(size.width / 2, size.height * 0.3);
    final opacity = t < 0.7 ? 1.0 : (1 - t) / 0.3;
    final paint = Paint();
    for (final p in pieces) {
      final x = origin.dx + p.vx * secs * unit;
      final y = origin.dy + (p.vy * secs + 0.5 * _gravity * secs * secs) * unit;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * secs);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
