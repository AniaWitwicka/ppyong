import 'package:flutter/material.dart';

class SquiggleBackground extends StatelessWidget {
  const SquiggleBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SquigglePainter(),
      child: child,
    );
  }
}

class _SquigglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pink = Paint()
      ..color = const Color(0xFFF296BD)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final orange = Paint()
      ..color = const Color(0xFFF5793B)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Top-left orange swoosh
    _drawSwoosh(canvas, orange, [
      Offset(w * -0.02, h * 0.08),
      Offset(w * 0.08, h * 0.18),
      Offset(w * -0.02, h * 0.28),
      Offset(w * 0.10, h * 0.38),
      Offset(w * 0.00, h * 0.50),
    ]);

    // Top-center pink wave
    _drawSwoosh(canvas, pink, [
      Offset(w * 0.20, h * -0.02),
      Offset(w * 0.35, h * 0.08),
      Offset(w * 0.22, h * 0.18),
      Offset(w * 0.38, h * 0.28),
      Offset(w * 0.25, h * 0.38),
      Offset(w * 0.40, h * 0.48),
    ]);

    // Top-right orange squiggle
    _drawSwoosh(canvas, orange, [
      Offset(w * 0.60, h * -0.02),
      Offset(w * 0.80, h * 0.06),
      Offset(w * 0.65, h * 0.15),
      Offset(w * 0.85, h * 0.24),
      Offset(w * 1.00, h * 0.18),
    ]);

    // Mid-right pink swoosh
    _drawSwoosh(canvas, pink, [
      Offset(w * 1.02, h * 0.35),
      Offset(w * 0.85, h * 0.45),
      Offset(w * 1.00, h * 0.55),
      Offset(w * 0.82, h * 0.65),
      Offset(w * 1.02, h * 0.74),
    ]);

    // Bottom-center orange wave
    _drawSwoosh(canvas, orange, [
      Offset(w * 0.15, h * 0.72),
      Offset(w * 0.35, h * 0.80),
      Offset(w * 0.18, h * 0.90),
      Offset(w * 0.38, h * 1.00),
      Offset(w * 0.22, h * 1.08),
    ]);

    // Bottom-right pink squiggle
    _drawSwoosh(canvas, pink, [
      Offset(w * 0.55, h * 0.78),
      Offset(w * 0.75, h * 0.86),
      Offset(w * 0.58, h * 0.94),
      Offset(w * 0.78, h * 1.02),
    ]);
  }

  void _drawSwoosh(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      if (i == 0) {
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
