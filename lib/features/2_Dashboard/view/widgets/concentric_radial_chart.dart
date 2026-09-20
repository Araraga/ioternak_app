import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConcentricRingData {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color? trackColor;

  const ConcentricRingData({
    required this.progress,
    required this.color,
    this.trackColor,
  });
}

/// A modern Apple-Watch style concentric radial chart (nested circles)
class ConcentricRadialChart extends StatelessWidget {
  final List<ConcentricRingData> rings;
  final double size;
  final double strokeWidth;
  final double ringSpacing;
  final Widget? centerWidget;
  final Duration animationDuration;

  const ConcentricRadialChart({
    super.key,
    required this.rings,
    this.size = 96,
    this.strokeWidth = 6.0,
    this.ringSpacing = 3.5,
    this.centerWidget,
    this.animationDuration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _ConcentricRingsPainter(
                  rings: rings,
                  animationValue: animValue,
                  strokeWidth: strokeWidth,
                  ringSpacing: ringSpacing,
                ),
              ),
              if (centerWidget != null) centerWidget!,
            ],
          ),
        );
      },
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  final List<ConcentricRingData> rings;
  final double animationValue;
  final double strokeWidth;
  final double ringSpacing;

  _ConcentricRingsPainter({
    required this.rings,
    required this.animationValue,
    required this.strokeWidth,
    required this.ringSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    for (int i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final radius = maxRadius - i * (strokeWidth + ringSpacing);
      if (radius <= strokeWidth / 2) break;

      // Track background (soft transparent version of ring color)
      final trackColor = ring.trackColor ?? ring.color.withValues(alpha: 0.15);
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, trackPaint);

      // Active Progress Arc
      final targetProgress = ring.progress.clamp(0.0, 1.0);
      final currentProgress = targetProgress * animationValue;

      if (currentProgress > 0.001) {
        final progressPaint = Paint()
          ..color = ring.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        final sweepAngle = 2 * math.pi * currentProgress;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, // Start at 12 o'clock (top)
          sweepAngle,
          false,
          progressPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rings != rings ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.ringSpacing != ringSpacing;
  }
}
