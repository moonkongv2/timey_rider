import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class VehicleWidget extends StatefulWidget {
  const VehicleWidget({
    super.key,
    required this.vehicle,
    this.size = 180,
    this.angle = 0,
    this.isArrived = false,
  });

  final VehicleDefinition vehicle;
  final double size;
  final double angle;
  final bool isArrived;

  @override
  State<VehicleWidget> createState() => _VehicleWidgetState();
}

class _VehicleWidgetState extends State<VehicleWidget>
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
  void didUpdateWidget(covariant VehicleWidget oldWidget) {
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
                    widget.vehicle.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Transform.flip(
                        flipX: true,
                        child: Text(
                          widget.vehicle.emoji,
                          textScaler: TextScaler.noScaling,
                          semanticsLabel: widget.vehicle.labelKo,
                          style: TextStyle(fontSize: widget.size * 0.58),
                        ),
                      );
                    },
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
