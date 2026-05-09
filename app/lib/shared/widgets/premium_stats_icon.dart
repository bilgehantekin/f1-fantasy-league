import 'package:flutter/material.dart';

class PremiumStatsIcon extends StatelessWidget {
  final double size;

  const PremiumStatsIcon({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFC9A24A);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PremiumStatsPainter(gold)),
    );
  }
}

class _PremiumStatsPainter extends CustomPainter {
  final Color color;

  const _PremiumStatsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = side * 0.085
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = side * 0.3;
    final bottom = side * 0.68;
    canvas.drawLine(Offset(left, side * 0.27), Offset(left, bottom), stroke);
    canvas.drawLine(Offset(left, bottom), Offset(side * 0.72, bottom), stroke);

    final trend = Path()
      ..moveTo(side * 0.43, side * 0.55)
      ..lineTo(side * 0.55, side * 0.43)
      ..lineTo(side * 0.63, side * 0.5)
      ..lineTo(side * 0.74, side * 0.38);
    canvas.drawPath(trend, stroke);
  }

  @override
  bool shouldRepaint(_PremiumStatsPainter oldDelegate) =>
      oldDelegate.color != color;
}
