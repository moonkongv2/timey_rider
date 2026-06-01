import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.assetPath = splashAnimationAssetPath,
  });

  static const splashAnimationAssetPath = 'assets/videos/splash_animation.mp4';

  final VoidCallback onFinished;
  final String assetPath;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _maxSplashDuration = Duration(milliseconds: 3500);

  VideoPlayerController? _controller;
  Timer? _fallbackTimer;
  Timer? _completionPollTimer;
  bool _didFinish = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(_maxSplashDuration, _finish);
    _initializeVideo();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _completionPollTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleVideoChanged);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    controller.addListener(_handleVideoChanged);

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      if (_didFinish) {
        return;
      }
      await controller.play();
      _completionPollTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _handleVideoChanged(),
      );
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (_) {
      _finish();
    }
  }

  void _handleVideoChanged() {
    final controller = _controller;
    if (controller == null || _didFinish) {
      return;
    }

    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) {
      return;
    }

    final remaining = value.duration - value.position;
    final isNearEnd = remaining <= const Duration(milliseconds: 250);
    final isStoppedNearEnd =
        !value.isPlaying &&
        value.position > Duration.zero &&
        remaining <= const Duration(milliseconds: 600);

    if (value.isCompleted ||
        value.position >= value.duration ||
        isNearEnd ||
        isStoppedNearEnd) {
      _finish();
    }
  }

  void _finish() {
    if (_didFinish || !mounted) {
      return;
    }

    _didFinish = true;
    _fallbackTimer?.cancel();
    _completionPollTimer?.cancel();
    Future<void>.microtask(() {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ClipRect(
        child:
            !_isReady || controller == null || !controller.value.isInitialized
            ? const SizedBox.expand()
            : SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
      ),
    );
  }
}
