import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/models.dart';

const shareGold = Color(0xFFFFD700);
const shareSilver = Color(0xFFC8CDD3);
const shareBronze = Color(0xFFD08B5B);

class ShareStoryFrame extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets padding;
  final Widget child;
  final Color accent;

  const ShareStoryFrame({
    super.key,
    required this.width,
    required this.height,
    required this.padding,
    required this.child,
    this.accent = AppColors.f1Red,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.carbon,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.carbon, Color(0xFF0E0E18), AppColors.surface],
            stops: [0, 0.62, 1],
          ),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: ShareTrackPainter(accent)),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class ShareTrackPainter extends CustomPainter {
  final Color color;

  const ShareTrackPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.06, size.height * 0.99)
      ..quadraticBezierTo(
        size.width * 0.04,
        size.height * 0.78,
        size.width * 0.28,
        size.height * 0.71,
      )
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.63,
        size.width * 0.60,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.32,
        size.width * 0.36,
        size.height * 0.25,
      )
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.18,
        size.width * 0.06,
        size.height * 0.03,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.20
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.10
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (var y = 0.08; y < 0.92; y += 0.055) {
      for (var x = 0.06; x < 0.96; x += 0.075) {
        canvas.drawCircle(
          Offset(size.width * x, size.height * y),
          1.4,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShareTrackPainter oldDelegate) =>
      oldDelegate.color != color;
}

class ShareGridCallLogo extends StatelessWidget {
  final double fontSize;
  final double bulbSize;

  const ShareGridCallLogo({super.key, this.fontSize = 40, this.bulbSize = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Container(
              width: bulbSize,
              height: bulbSize,
              margin: EdgeInsets.only(right: bulbSize * 0.35),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.45),
                  colors: [
                    Color(0xFFFF5A5A),
                    AppColors.f1Red,
                    Color(0xFF690000),
                  ],
                  stops: [0, 0.52, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.f1Red.withValues(alpha: 0.65),
                    blurRadius: bulbSize,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: bulbSize * 0.9),
        Text(
          'GRIDCALL',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class ShareSeasonPill extends StatelessWidget {
  final String label;

  const ShareSeasonPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.f1Red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ShareStandingLine extends StatelessWidget {
  final StandingRow row;
  final bool compact;

  const ShareStandingLine({super.key, required this.row, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 26,
        vertical: compact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 42 : 50,
            child: Text(
              '${row.rank}',
              style: TextStyle(
                fontSize: compact ? 28 : 32,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 26 : 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '${row.score}',
            style: TextStyle(
              fontSize: compact ? 28 : 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'PUAN',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShareInviteBox extends StatelessWidget {
  final String code;
  final String label;

  const ShareInviteBox({
    super.key,
    required this.code,
    this.label = 'SEN DE KATIL',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.f1Red.withValues(alpha: 0.18),
            AppColors.f1Red.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.f1Red.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'davet kodu',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Text(
            code,
            style: const TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
