import 'package:flutter/material.dart';

class SparkleLoader extends StatefulWidget {
  const SparkleLoader({
    super.key,
    required this.label,
    this.caption,
    this.compact = false,
  });

  final String label;
  final String? caption;
  final bool compact;

  @override
  State<SparkleLoader> createState() => _SparkleLoaderState();
}

class _SparkleLoaderState extends State<SparkleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 18.0 : 28.0;
    final spacing = widget.compact ? 10.0 : 14.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_controller.value);
            return Transform.scale(
              scale: 0.88 + (t * 0.22),
              child: Transform.rotate(
                angle: t * 0.15,
                child: child,
              ),
            );
          },
          child: Icon(
            Icons.auto_awesome_rounded,
            size: iconSize,
            color: const Color(0xFF2368AF),
          ),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF243142),
                ),
              ),
              if (widget.caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.caption!,
                  style: TextStyle(
                    fontSize: widget.compact ? 11 : 13,
                    color: const Color(0xFF6C7889),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
