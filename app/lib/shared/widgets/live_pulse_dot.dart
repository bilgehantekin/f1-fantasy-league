import 'package:flutter/material.dart';

/// Yanıp sönen kırmızı LIVE noktası — figma React `<LiveIndicator/>` portu.
/// İç dolu daire sabit, dış halka her döngüde büyüyüp solar.
class LivePulseDot extends StatefulWidget {
  final double size;
  final Color color;
  const LivePulseDot({
    super.key,
    this.size = 16,
    this.color = const Color(0xFFFF2D55),
  });

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reserved = widget.size + 4;
    final innerSize = widget.size * 0.62;
    return SizedBox(
      width: reserved,
      height: reserved,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            final ringSize = innerSize + (widget.size + 4) * t;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.7 * (1 - t)),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
