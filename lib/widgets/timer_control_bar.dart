import 'package:flutter/material.dart';

class TimerControlBar extends StatelessWidget {
  const TimerControlBar({
    super.key,
    required this.isPaused,
    required this.onPauseResume,
    required this.onComplete,
  });

  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPauseResume,
            icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause),
            label: Text(isPaused ? '다시 출발' : '일시정지'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('식사 완료'),
          ),
        ),
      ],
    );
  }
}
