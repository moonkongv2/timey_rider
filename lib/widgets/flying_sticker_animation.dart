import 'package:flutter/material.dart';

import '../models/reward_item.dart';
import 'reward_sticker_image.dart';

class FlyingStickerAnimation extends StatefulWidget {
  const FlyingStickerAnimation({
    super.key,
    required this.reward,
    required this.targetKey,
    required this.onAnimationFinished,
  });

  final RewardDefinition reward;
  final GlobalKey targetKey;
  final VoidCallback onAnimationFinished;

  @override
  State<FlyingStickerAnimation> createState() => _FlyingStickerAnimationState();
}

class _FlyingStickerAnimationState extends State<FlyingStickerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleUpAnimation;
  late final Animation<double> _flyAnimation;

  Offset? _targetOffset;
  Size? _targetSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleUpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _flyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationFinished();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTarget();
      if (mounted) {
        _controller.forward();
      }
    });
  }

  void _calculateTarget() {
    final renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _targetOffset = renderBox.localToGlobal(Offset.zero);
      _targetSize = renderBox.size;
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
        final screenCenter = MediaQuery.of(context).size.center(Offset.zero);
        final startSize = 200.0;
        final startOffset = screenCenter - Offset(startSize / 2, startSize / 2);

        final currentSize = _targetSize != null && _flyAnimation.value > 0
            ? startSize + (_targetSize!.width - startSize) * _flyAnimation.value
            : startSize * _scaleUpAnimation.value;

        final currentOffset = _targetOffset != null && _flyAnimation.value > 0
            ? Offset.lerp(startOffset, _targetOffset, _flyAnimation.value)!
            : startOffset;

        if (_scaleUpAnimation.value == 0) return const SizedBox.shrink();

        return Positioned(
          left: currentOffset.dx,
          top: currentOffset.dy,
          width: currentSize,
          height: currentSize,
          child: Opacity(
            opacity: _flyAnimation.value > 0.9 ? 1.0 - (_flyAnimation.value - 0.9) * 10 : 1.0,
            child: RewardStickerImage(
              reward: widget.reward,
              size: currentSize,
              locked: false,
            ),
          ),
        );
      },
    );
  }
}
