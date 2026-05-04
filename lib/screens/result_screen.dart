import 'dart:math';

import 'package:flutter/material.dart';

import '../models/meal_session_result.dart';
import '../models/meal_timer_config.dart';
import 'home_screen.dart';
import 'timer_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.config,
    required this.onConfigChanged,
  });

  final MealSessionResult result;
  final MealTimerConfig config;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  static const _rewardStickers = ['🏁 도착 깃발 스티커', '⭐ 반짝 별 스티커', '🪖 멋진 헬멧 스티커'];

  void _restart(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            TimerScreen(config: config, onConfigChanged: onConfigChanged),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            HomeScreen(config: config, onConfigChanged: onConfigChanged),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedBeforeArrival = result.completedBeforeArrival;
    final sticker = completedBeforeArrival
        ? _rewardStickers[Random(
            result.startedAt.millisecondsSinceEpoch,
          ).nextInt(_rewardStickers.length)]
        : '🏍️ 오늘의 라이더 스티커';

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
                            : '다음 밥길도 같이 달려보자.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1B8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Text(
                            sticker,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
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
