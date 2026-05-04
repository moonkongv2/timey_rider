import 'package:flutter/material.dart';

import '../controllers/meal_timer_controller.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../services/local_meal_progress_service.dart';
import '../utils/duration_format.dart';
import '../widgets/meal_message_card.dart';
import '../widgets/road_view.dart';
import '../widgets/timer_control_bar.dart';
import 'result_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = MealTimerController(config: widget.config)..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('식사를 완료했어?'),
          content: const Text('오늘의 냠냠코스를 마무리할까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아직이야'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('완료'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
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

  String _messageFor(MealTimerController controller) {
    if (controller.isPaused) {
      return '잠깐 쉬는 중이야';
    }

    final progress = controller.progress;
    if (progress < 0.25) {
      return '부릉부릉 출발! 냠냠코스를 달려보자.';
    }
    if (progress < 0.5) {
      return '좋아, 천천히 꼭꼭 씹으면서 가고 있어.';
    }
    if (progress < 0.75) {
      return '절반쯤 왔어. 오늘도 잘하고 있어!';
    }
    if (progress < 1.0) {
      return '도착이 가까워졌어. 마지막까지 같이 가보자.';
    }
    return '오토바이가 도착했어. 오늘도 식사하느라 수고했어.';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('오늘의 냠냠코스')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  MealMessageCard(message: _messageFor(_controller)),
                  const SizedBox(height: 16),
                  Expanded(child: RoadView(progress: _controller.progress)),
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
              '남은 시간 ${formatDuration(remaining)}',
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
