import 'package:flutter/material.dart';

import '../models.dart';

Color _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF6E6E80);
  final s = hex.replaceAll('#', '');
  final v = int.tryParse(s, radix: 16);
  if (v == null) return const Color(0xFF6E6E80);
  return s.length == 6 ? Color(0xFFFF000000 | v) : Color(v);
}

class DriverChip extends StatelessWidget {
  final Driver driver;
  final bool selected;
  final bool dense;
  const DriverChip({
    super.key,
    required this.driver,
    this.selected = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(driver.teamColor);
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 14, vertical: dense ? 8 : 12),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.18)
            : const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: dense ? 24 : 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(driver.code,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: dense ? 14 : 17,
                      )),
                  if (driver.number != null) ...[
                    const SizedBox(width: 6),
                    Text('#${driver.number}',
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white54,
                          fontSize: dense ? 10 : 11,
                        )),
                  ],
                ],
              ),
              if (!dense)
                Text(driver.fullName,
                    style: tt.bodySmall
                        ?.copyWith(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverChipSlot extends StatelessWidget {
  final Driver? driver;
  final String hint;
  final bool enabled;
  final VoidCallback? onTap;
  const DriverChipSlot({
    super.key,
    required this.driver,
    required this.hint,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (driver != null) {
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: DriverChip(driver: driver!, selected: true),
      );
    }
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white24,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: Colors.white54, size: 20),
            const SizedBox(width: 10),
            Text(hint,
                style: const TextStyle(
                    color: Colors.white60, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
