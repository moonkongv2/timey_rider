import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.assetPath = splashAnimationAssetPath,
  });

  static const splashAnimationAssetPath =
      'assets/videos/splash_animation.json';

  final VoidCallback onFinished;
  final String assetPath;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _maxSplashDuration = Duration(milliseconds: 3500);
  static const _horizontalOffsetFraction = -0.08;

  late final AnimationController _controller;
  Timer? _fallbackTimer;
  bool _didFinish = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finish();
        }
      });
    _fallbackTimer = Timer(_maxSplashDuration, _finish);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_didFinish || !mounted) {
      return;
    }

    _didFinish = true;
    _fallbackTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  Future<LottieComposition?> _decodeDotLottie(List<int> bytes) {
    return LottieComposition.decodeZip(
      bytes,
      filePicker: (files) {
        for (final file in files) {
          if (file.name.startsWith('animations/') &&
              file.name.endsWith('.json')) {
            return file;
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Transform.translate(
              offset: Offset(
                constraints.maxWidth * _horizontalOffsetFraction,
                0,
              ),
              child: SizedBox.expand(
                child: Lottie.asset(
                  widget.assetPath,
                  controller: _controller,
                  fit: BoxFit.cover,
                  delegates: LottieDelegates(
                    textStyle: (font) =>
                        const TextStyle(fontFamily: 'Cal Sans'),
                  ),
                  decoder: widget.assetPath.endsWith('.lottie')
                      ? _decodeDotLottie
                      : null,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..forward();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    _finish();
                    return const SizedBox.shrink();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
