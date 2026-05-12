import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum AppButtonVariant { primary, soft, neutral, outline }

enum AppButtonSize { large, medium, compact }

class AppBouncyButton extends StatefulWidget {
  const AppBouncyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.minHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? minHeight;

  @override
  State<AppBouncyButton> createState() => _AppBouncyButtonState();
}

class _AppBouncyButtonState extends State<AppBouncyButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || widget.onPressed == null) {
      return;
    }
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final sizeStyle = _ButtonSizeStyle.forSize(widget.size);
    final variantStyle = _ButtonVariantStyle.forVariant(widget.variant);
    final backgroundColor = isEnabled
        ? widget.backgroundColor ?? variantStyle.backgroundColor
        : AppColors.brown300.withValues(alpha: 0.30);
    final foregroundColor = isEnabled
        ? widget.foregroundColor ?? variantStyle.foregroundColor
        : AppColors.brown500.withValues(alpha: 0.56);
    final border = widget.variant == AppButtonVariant.outline
        ? Border.all(color: AppColors.borderSoft, width: 1.5)
        : variantStyle.border;
    final boxShadow = isEnabled ? variantStyle.boxShadow : null;

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: AnimatedScale(
        duration: AppMotion.fast,
        curve: AppMotion.playfulCurve,
        scale: _isPressed ? 0.96 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.button,
            border: border,
            boxShadow: boxShadow,
          ),
          child: Material(
            color: AppColors.transparent,
            borderRadius: AppRadius.button,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.minHeight ?? sizeStyle.minHeight,
                ),
                child: Padding(
                  padding: sizeStyle.padding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: widget.fullWidth
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: foregroundColor,
                          size: sizeStyle.iconSize,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: sizeStyle
                              .textStyle(context)
                              .copyWith(color: foregroundColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonVariantStyle {
  const _ButtonVariantStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
    this.boxShadow,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  static _ButtonVariantStyle forVariant(AppButtonVariant variant) {
    return switch (variant) {
      AppButtonVariant.primary => _ButtonVariantStyle(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        boxShadow: AppShadows.buttonPrimary,
      ),
      AppButtonVariant.soft => _ButtonVariantStyle(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.brown900,
        border: Border.all(color: AppColors.borderWarm, width: 1.2),
        boxShadow: AppShadows.buttonSoft,
      ),
      AppButtonVariant.neutral => _ButtonVariantStyle(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.brown700,
        border: Border.all(color: AppColors.borderSoft, width: 1.2),
      ),
      AppButtonVariant.outline => _ButtonVariantStyle(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.brown700,
      ),
    };
  }
}

class _ButtonSizeStyle {
  const _ButtonSizeStyle({
    required this.minHeight,
    required this.padding,
    required this.iconSize,
    required this.textStyle,
  });

  final double minHeight;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final TextStyle Function(BuildContext context) textStyle;

  static _ButtonSizeStyle forSize(AppButtonSize size) {
    return switch (size) {
      AppButtonSize.large => _ButtonSizeStyle(
        minHeight: 60,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        iconSize: 24,
        textStyle: (context) =>
            Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800) ??
            const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      AppButtonSize.medium => _ButtonSizeStyle(
        minHeight: 54,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        iconSize: 22,
        textStyle: (context) =>
            Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      AppButtonSize.compact => _ButtonSizeStyle(
        minHeight: 46,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        iconSize: 20,
        textStyle: (context) =>
            Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800) ??
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    };
  }
}
