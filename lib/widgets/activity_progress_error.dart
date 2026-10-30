import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../services/local_activity_progress_service.dart';

String activityProgressErrorMessage(
  BuildContext context,
  Object? error, {
  bool saving = false,
}) {
  final texts = AppTexts.of(context).activityHistory;
  if (error is ActivityProgressDataException) return texts.dataFailureMessage;
  return saving ? texts.storageFailureMessage : texts.loadFailureMessage;
}

class ActivityProgressError extends StatelessWidget {
  const ActivityProgressError({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activityProgressErrorMessage(context, error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(AppTexts.of(context).common.retry),
          ),
        ],
      ),
    ),
  );
}
