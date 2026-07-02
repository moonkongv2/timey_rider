import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_texts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../app/app_bouncy_button.dart';

typedef ParentGatePresenter = Future<bool> Function(BuildContext context);

@immutable
class ParentGateChallenge {
  const ParentGateChallenge({required this.left, required this.right});

  factory ParentGateChallenge.random([Random? random]) {
    final source = random ?? Random();
    return ParentGateChallenge(
      left: 8 + source.nextInt(12),
      right: 4 + source.nextInt(8),
    );
  }

  final int left;
  final int right;

  int get answer => left + right;
}

Future<bool> showParentGateSheet(
  BuildContext context, {
  ParentGateChallenge? challenge,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    builder: (_) =>
        ParentGateSheet(challenge: challenge ?? ParentGateChallenge.random()),
  );

  return result ?? false;
}

class ParentGateSheet extends StatefulWidget {
  const ParentGateSheet({super.key, required this.challenge});

  final ParentGateChallenge challenge;

  @override
  State<ParentGateSheet> createState() => _ParentGateSheetState();
}

class _ParentGateSheetState extends State<ParentGateSheet> {
  final _answerController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = int.tryParse(_answerController.text.trim());
    if (answer == widget.challenge.answer) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorText = AppTexts.of(context).purchase.parentGateErrorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final purchaseTexts = texts.purchase;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  purchaseTexts.parentGateTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  purchaseTexts.parentGateSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          purchaseTexts.parentGateQuestion(
                            widget.challenge.left,
                            widget.challenge.right,
                          ),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.textStrong,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          key: const ValueKey('parentGateAnswerField'),
                          controller: _answerController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: purchaseTexts.parentGateAnswerLabel,
                            errorText: _errorText,
                          ),
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppBouncyButton(
                  key: const ValueKey('parentGateContinueButton'),
                  label: purchaseTexts.parentGateContinueButton,
                  icon: Icons.lock_open_rounded,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(texts.common.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
