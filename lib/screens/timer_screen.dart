import 'package:flutter/material.dart';

import '../controllers/meal_timer_controller.dart';
import '../l10n/app_texts.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../services/local_meal_progress_service.dart';
import '../utils/duration_format.dart';
import '../widgets/road_view.dart';
import '../widgets/timer_control_bar.dart';
import 'result_screen.dart';

const _motivationVideoByMilestone = {
  10: 'assets/videos/motivation_10.mp4',
  20: 'assets/videos/motivation_10.mp4',
  30: 'assets/videos/motivation_10.mp4',
  40: 'assets/videos/motivation_10.mp4',
  50: 'assets/videos/motivation_10.mp4',
  60: 'assets/videos/motivation_10.mp4',
  70: 'assets/videos/motivation_10.mp4',
  80: 'assets/videos/motivation_10.mp4',
  90: 'assets/videos/motivation_10.mp4',
  // 20: 'assets/videos/motivation_20.mp4',
  // 30: 'assets/videos/motivation_30.mp4',
  // 40: 'assets/videos/motivation_40.mp4',
  // 50: 'assets/videos/motivation_50.mp4',
  // 60: 'assets/videos/motivation_60.mp4',
  // 70: 'assets/videos/motivation_70.mp4',
  // 80: 'assets/videos/motivation_80.mp4',
  // 90: 'assets/videos/motivation_90.mp4',
};

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
  });

  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final MealTimerController _controller;
  final Set<int> _shownMotivationMilestones = {};
  bool _arrivalPromptShown = false;
  int? _activeMotivationMilestone;
  String? _activeMotivationVideoPath;

  @override
  void initState() {
    super.initState();
    _controller = MealTimerController(config: widget.config);
    _controller.addListener(_handleTimerChanged);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTimerChanged() {
    _maybeShowMotivationVideo();

    if (_arrivalPromptShown ||
        _controller.state != MealTimerState.arrived ||
        !mounted) {
      return;
    }

    _arrivalPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) {
        return;
      }
      _confirmComplete(showFailureOnDecline: true);
    });
  }

  void _maybeShowMotivationVideo() {
    if (!mounted || _controller.progress >= 1) {
      return;
    }

    final milestone = (_controller.progress * 10).floor() * 10;
    if (milestone < 10 || milestone > 90) {
      return;
    }

    if (!_shownMotivationMilestones.add(milestone)) {
      return;
    }

    if (_activeMotivationMilestone != null) {
      return;
    }

    final videoPath = _motivationVideoByMilestone[milestone];
    if (videoPath == null) {
      return;
    }

    setState(() {
      _activeMotivationMilestone = milestone;
      _activeMotivationVideoPath = videoPath;
    });
  }

  void _handleMotivationVideoFinished() {
    if (!mounted || _activeMotivationMilestone == null) {
      return;
    }

    setState(() {
      _activeMotivationMilestone = null;
      _activeMotivationVideoPath = null;
    });
  }

  Future<void> _confirmComplete({bool showFailureOnDecline = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !showFailureOnDecline,
      builder: (context) {
        return AlertDialog(
          title: Text(AppTexts.timer.completeDialogTitle),
          content: Text(
            showFailureOnDecline
                ? AppTexts.timer.arrivalDialogMessage
                : AppTexts.timer.completeDialogMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppTexts.common.notYet),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppTexts.common.complete),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (confirmed != true) {
      if (showFailureOnDecline) {
        final result = _controller.complete(mealCompleted: false);
        _openResult(result);
      }
      return;
    }

    final result = _controller.complete();
    _openResult(result);
  }

  void _openResult(MealSessionResult result) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          result: result,
          config: widget.config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(AppTexts.timer.courseTitle)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Expanded(
                    child: RoadView(
                      progress: _controller.progress,
                      motivationVideoAssetPath: _activeMotivationVideoPath,
                      motivationVideoMilestone: _activeMotivationMilestone,
                      onMotivationVideoFinished: _handleMotivationVideoFinished,
                    ),
                  ),
                  if (widget.config.showRemainingTime) ...[
                    const SizedBox(height: 16),
                    _RemainingTimeCard(remaining: _controller.remaining),
                  ],
                  const SizedBox(height: 16),
                  TimerControlBar(
                    isPaused: _controller.isPaused,
                    onPauseResume: () {
                      if (_controller.isPaused) {
                        _controller.resume();
                      } else {
                        _controller.pause();
                      }
                    },
                    onComplete: _confirmComplete,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RemainingTimeCard extends StatelessWidget {
  const _RemainingTimeCard({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_rounded),
            const SizedBox(width: 8),
            Text(
              AppTexts.timer.remainingTime(formatDuration(remaining)),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
