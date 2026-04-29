import 'package:flutter/material.dart';

class CountdownTiles extends StatelessWidget {
  final Duration remaining;
  final bool locked;
  const CountdownTiles({super.key, required this.remaining, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (locked || remaining.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9F1C).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFF9F1C), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Color(0xFFFF9F1C), size: 18),
            const SizedBox(width: 8),
            Text('KİLİTLİ',
                style: tt.labelLarge
                    ?.copyWith(color: const Color(0xFFFF9F1C))),
          ],
        ),
      );
    }

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final mins = remaining.inMinutes.remainder(60);
    final secs = remaining.inSeconds.remainder(60);

    // Urgency color
    final urgent = remaining.inHours < 6;
    final color = urgent ? const Color(0xFFFF2D55) : const Color(0xFF00D26A);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[
          _Tile(value: days, label: 'GÜN', color: color),
          const SizedBox(width: 6),
        ],
        _Tile(value: hours, label: 'SAAT', color: color, twoDigit: true),
        const SizedBox(width: 6),
        _Tile(value: mins, label: 'DK', color: color, twoDigit: true),
        const SizedBox(width: 6),
        _Tile(value: secs, label: 'SN', color: color, twoDigit: true),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final bool twoDigit;
  const _Tile({
    required this.value,
    required this.label,
    required this.color,
    this.twoDigit = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final v = twoDigit ? value.toString().padLeft(2, '0') : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v,
              style: tt.headlineLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -1,
              )),
          Text(label,
              style: tt.labelSmall?.copyWith(
                color: Colors.white60,
                fontSize: 9,
                letterSpacing: 1.2,
              )),
        ],
      ),
    );
  }
}
