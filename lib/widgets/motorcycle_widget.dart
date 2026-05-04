import 'dart:math' as math;

import 'package:flutter/material.dart';

class MotorcycleWidget extends StatefulWidget {
  const MotorcycleWidget({
    super.key,
    this.size = 180,
    this.angle = 0,
    this.isArrived = false,
  });

  final double size;
  final double angle;
  final bool isArrived;

  @override
  State<MotorcycleWidget> createState() => _MotorcycleWidgetState();
}

class _MotorcycleWidgetState extends State<MotorcycleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (!widget.isArrived) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MotorcycleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isArrived == oldWidget.isArrived) {
      return;
    }
    if (widget.isArrived) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bouncePhase = widget.isArrived
            ? 0.0
            : (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final bounceOffset = -bouncePhase * 5;
        final shadowScale = 1 - (bouncePhase * 0.14);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: widget.size * 0.13,
                child: Transform.scale(
                  scaleX: shadowScale,
                  child: Container(
                    width: widget.size * 0.48,
                    height: widget.size * 0.12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B4636).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(widget.size),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, bounceOffset),
                child: Transform.rotate(
                  angle: widget.angle * 0.32,
                  child: Image.asset(
                    'assets/images/jy_the_rider_flipped.png',
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
