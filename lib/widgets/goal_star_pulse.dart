import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoalStarPulse extends StatefulWidget {
  const GoalStarPulse({
    super.key,
    this.size = 56,
    this.assetPath = _defaultAssetPath,
    this.semanticLabel = 'finish point',
    this.isPulsing = true,
  });

  static const _defaultAssetPath = 'assets/images/goal_star.svg';

  final double size;
  final String assetPath;
  final String semanticLabel;
  final bool isPulsing;

  @override
  State<GoalStarPulse> createState() => _GoalStarPulseState();
}

class _GoalStarPulseState extends State<GoalStarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _disableAnimations =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  bool get _shouldPulse => widget.isPulsing && !_disableAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant GoalStarPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPulsing != widget.isPulsing) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (_shouldPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulseValue = _shouldPulse ? _controller.value : 0.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + (pulseValue * 0.62),
                  child: Opacity(
                    opacity: 0.42 - (pulseValue * 0.36),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFDC71),
                          width: widget.size * 0.075,
                        ),
                      ),
                      child: SizedBox.square(dimension: widget.size * 0.82),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: _shouldPulse ? _scaleAnimation.value : 1,
                  child: child,
                ),
              ],
            );
          },
          child: SvgPicture.asset(
            widget.assetPath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
