import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../models.dart';
import 'driver_chip.dart';

class PodiumDisplay extends StatelessWidget {
  final Driver? p1;
  final Driver? p2;
  final Driver? p3;
  const PodiumDisplay({
    super.key,
    required this.p1,
    required this.p2,
    required this.p3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumPos(driver: p2, place: 2, height: 140)),
          Expanded(child: _PodiumPos(driver: p1, place: 1, height: 190)),
          Expanded(child: _PodiumPos(driver: p3, place: 3, height: 110)),
        ],
      ),
    );
  }
}

class _PodiumPos extends StatelessWidget {
  final Driver? driver;
  final int place;
  final double height;
  const _PodiumPos(
      {required this.driver, required this.place, required this.height});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final medalColor = switch (place) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      _ => const Color(0xFFCD7F32),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (driver != null)
            DriverChip(driver: driver!, dense: true)
          else
            const SizedBox(height: 40),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  medalColor.withValues(alpha: 0.4),
                  medalColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
              border: Border(
                top: BorderSide(color: medalColor, width: 2),
                left: BorderSide(color: medalColor.withValues(alpha: 0.4)),
                right: BorderSide(color: medalColor.withValues(alpha: 0.4)),
              ),
            ),
            child: Center(
              child: Text('P$place',
                  style: tt.displayMedium?.copyWith(
                    color: medalColor,
                    fontSize: 32,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class PointsBreakdownTile extends StatelessWidget {
  final String label;
  final String value;
  final int? points;
  final bool? correct;
  const PointsBreakdownTile({
    super.key,
    required this.label,
    required this.value,
    this.points,
    this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = correct == null
        ? Colors.white60
        : (correct! ? AppColors.lockGreen : AppColors.liveRed);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.labelSmall
                        ?.copyWith(color: Colors.white54, fontSize: 10)),
                Text(value,
                    style: tt.titleMedium?.copyWith(letterSpacing: 0)),
              ],
            ),
          ),
          if (points != null && points! > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.f1Red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('+$points',
                  style: tt.labelLarge
                      ?.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }
}
