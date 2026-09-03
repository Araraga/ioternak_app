import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tombol AI dengan animasi liquid water shimmer
class LiquidActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const LiquidActionButton({
    super.key,
    required this.onTap,
    required this.child,
    this.size = 72,
  });

  @override
  State<LiquidActionButton> createState() => _LiquidActionButtonState();
}

class _LiquidActionButtonState extends State<LiquidActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotateController,
          _pulseController,
          _shimmerController,
        ]),
        builder: (context, child) {
          final pulse = _pulseController.value;
          final rotate = _rotateController.value * 2 * math.pi;
          final scale = _pressed ? 0.92 : (1.0 + pulse * 0.04);

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size + 16,
              height: widget.size + 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: widget.size + 16,
                    height: widget.size + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.aiGradientStart.withOpacity(0.3 * pulse),
                          AppColors.aiGradientEnd.withOpacity(0.1 * pulse),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Rotating shimmer ring
                  Transform.rotate(
                    angle: rotate,
                    child: Container(
                      width: widget.size + 8,
                      height: widget.size + 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.6),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.25, 0.5],
                        ),
                      ),
                    ),
                  ),

                  // Main button
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment(
                              math.cos(rotate) * 0.5,
                              math.sin(rotate) * 0.5,
                            ),
                            end: Alignment(
                              -math.cos(rotate) * 0.5,
                              -math.sin(rotate) * 0.5,
                            ),
                            colors: const [
                              AppColors.aiGradientStart,
                              AppColors.aiGradientMid,
                              AppColors.aiGradientEnd,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.aiGradientStart
                                  .withOpacity(0.5 + pulse * 0.2),
                              blurRadius: 20 + pulse * 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Water shimmer overlay
                            Positioned(
                              left: -widget.size * (1 - _shimmerController.value),
                              top: 0,
                              child: Container(
                                width: widget.size * 0.5,
                                height: widget.size,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                            // Icon
                            Center(child: child),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
