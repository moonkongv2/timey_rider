import 'package:flutter/material.dart';

import '../l10n/app_texts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ChildNameSetupScreen extends StatefulWidget {
  const ChildNameSetupScreen({super.key, required this.onNameSaved});

  final Future<void> Function(String name) onNameSaved;

  @override
  State<ChildNameSetupScreen> createState() => _ChildNameSetupScreenState();
}

class _ChildNameSetupScreenState extends State<ChildNameSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    await widget.onNameSaved(name);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      texts.settings.childNameSetupTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      texts.settings.childNameSetupSubtitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: texts.settings.childNameFieldLabel,
                        hintText: texts.common.defaultChildName,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _controller.text.trim().isEmpty || _isSaving
                          ? null
                          : _save,
                      child: Text(texts.settings.saveChildName),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
