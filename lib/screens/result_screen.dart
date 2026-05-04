import 'package:flutter/material.dart';

import '../models/meal_progress_snapshot.dart';
import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import '../models/reward_item.dart';
import '../services/local_meal_progress_service.dart';
import 'home_screen.dart';
import 'timer_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.config,
    required this.mealProgressService,
    required this.onConfigChanged,
  });

  final MealSessionResult result;
  final MealTimerConfig config;
  final LocalMealProgressService mealProgressService;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final Future<RecordedMealSession> _recordedSession = widget
      .mealProgressService
      .recordMealResult(widget.result);

  void _restart(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          config: widget.config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          config: widget.config,
          mealProgressService: widget.mealProgressService,
          onConfigChanged: widget.onConfigChanged,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedBeforeArrival = widget.result.completedBeforeArrival;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        completedBeforeArrival ? '식사 완주 성공!' : '오늘도 수고했어!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        completedBeforeArrival
                            ? '오토바이가 도착하기 전에 식사를 마쳤어.'
                            : '오토바이가 먼저 도착했지만, 식사하느라 정말 수고했어.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        completedBeforeArrival
                            ? '오늘도 멋진 라이더였어!'
                            : '다음 냠냠코스도 같이 달려보자.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder<RecordedMealSession>(
                        future: _recordedSession,
                        builder: (context, snapshot) {
                          return _RewardResultBox(
                            rewards: snapshot.data?.awardedRewards,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _restart(context),
                icon: const Icon(Icons.two_wheeler_rounded),
                label: const Text('다시 출발'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _goHome(context),
                icon: const Icon(Icons.home_rounded),
                label: const Text('홈으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardResultBox extends StatelessWidget {
  const _RewardResultBox({required this.rewards});

  final List<RewardDefinition>? rewards;

  @override
  Widget build(BuildContext context) {
    final labels = rewards
        ?.map((reward) => reward.displayLabel)
        .toList(growable: false);
    final text = labels == null
        ? '보상 정리 중...'
        : labels.isEmpty
        ? '오늘의 기록을 저장했어'
        : labels.join('\n');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1B8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
