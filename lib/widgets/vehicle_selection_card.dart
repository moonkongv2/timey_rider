import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../models/vehicle.dart';
import '../models/vehicle_avatar_presentation.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'avatar/avatar_composite_preview.dart';

typedef VehicleAvatarPresentationResolver =
    VehicleAvatarPresentation? Function(String vehicleId);

class VehicleSelectionCard extends StatelessWidget {
  const VehicleSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selectedVehicleId,
    required this.onVehicleSelected,
    this.avatar = VehicleAvatarPresentation.defaultImage,
    this.avatarForVehicle,
    this.avatarImageBuilder,
    this.showSelectedPreview = false,
    this.showChoices = true,
    this.actionLabel,
    this.actionButtonKey,
    this.onActionPressed,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final String selectedVehicleId;
  final ValueChanged<String> onVehicleSelected;
  final VehicleAvatarPresentation avatar;
  final VehicleAvatarPresentationResolver? avatarForVehicle;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;
  final bool showSelectedPreview;
  final bool showChoices;
  final String? actionLabel;
  final Key? actionButtonKey;
  final VoidCallback? onActionPressed;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = VehicleCatalog.findById(selectedVehicleId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Flexible(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.68),
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    key: actionButtonKey,
                    onPressed: onActionPressed,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (showSelectedPreview) ...[
              _SelectedVehiclePreview(
                vehicle: selectedVehicle,
                avatar: avatar,
                avatarImageBuilder: avatarImageBuilder,
              ),
              if (showChoices) const SizedBox(height: AppSpacing.md),
            ],
            if (showChoices)
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = AppSpacing.sm;
                  final threeAcrossWidth =
                      (constraints.maxWidth - (spacing * 2)) / 3;
                  final itemSize = threeAcrossWidth
                      .clamp(72.0, 128.0)
                      .toDouble();

                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing,
                    runSpacing: spacing,
                    clipBehavior: Clip.none,
                    children: [
                      for (final vehicle in VehicleCatalog.all)
                        _VehicleChoiceButton(
                          size: itemSize,
                          vehicle: vehicle,
                          isSelected: selectedVehicle.id == vehicle.id,
                          onTap: () => onVehicleSelected(vehicle.id),
                          avatar: avatar,
                          resolvedAvatar: avatarForVehicle?.call(vehicle.id),
                          avatarImageBuilder: avatarImageBuilder,
                        ),
                    ],
                  );
                },
              ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(
                color: AppColors.borderSoft,
                height: 1,
                thickness: 1,
              ),
              const SizedBox(height: AppSpacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedVehiclePreview extends StatelessWidget {
  const _SelectedVehiclePreview({
    required this.vehicle,
    required this.avatar,
    this.avatarImageBuilder,
  });

  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = vehicle.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final previewImageSize = avatar.isCustom ? 96.0 : 120.0;

    return Semantics(
      label: vehicleLabel,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceYellow.withValues(alpha: 0.42),
          borderRadius: AppRadius.compactCard,
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: SizedBox(
          key: const ValueKey('selectedVehiclePreview'),
          height: 120,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: previewImageSize,
              height: previewImageSize,
              child: _VehicleChoiceImage(
                vehicle: vehicle,
                size: previewImageSize,
                avatar: avatar,
                avatarImageBuilder: avatarImageBuilder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleChoiceButton extends StatelessWidget {
  const _VehicleChoiceButton({
    required this.size,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
    required this.avatar,
    required this.resolvedAvatar,
    this.avatarImageBuilder,
  });

  final double size;
  final VehicleDefinition vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  final VehicleAvatarPresentation avatar;
  final VehicleAvatarPresentation? resolvedAvatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primarySoft
        : AppColors.borderSoft;
    final backgroundColor = isSelected
        ? AppColors.surfaceYellow.withValues(alpha: 0.72)
        : AppColors.white.withValues(alpha: 0.72);
    final borderRadius = AppRadius.compactCard;
    final resolvedChoiceAvatar = resolvedAvatar;
    final choiceAvatar =
        resolvedChoiceAvatar != null && resolvedChoiceAvatar.isCustom
        ? resolvedChoiceAvatar
        : isSelected
        ? avatar
        : VehicleAvatarPresentation.defaultImage;

    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: vehicle.labelForLanguage(
          Localizations.localeOf(context).languageCode,
        ),
        button: true,
        selected: isSelected,
        child: Material(
          key: ValueKey('vehicleChoice.${vehicle.id}'),
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: size - 20,
                    height: size - 24,
                    child: _VehicleChoiceImage(
                      vehicle: vehicle,
                      size: size - 20,
                      avatar: choiceAvatar,
                      avatarImageBuilder: avatarImageBuilder,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.pill,
                        boxShadow: AppShadows.buttonSoft,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleChoiceImage extends StatelessWidget {
  const _VehicleChoiceImage({
    required this.vehicle,
    required this.size,
    required this.avatar,
    this.avatarImageBuilder,
  });

  final VehicleDefinition vehicle;
  final double size;
  final VehicleAvatarPresentation avatar;
  final Widget Function(BuildContext context, String imagePath)?
  avatarImageBuilder;

  @override
  Widget build(BuildContext context) {
    if (avatar.isCustom) {
      return AvatarCompositePreview(
        vehicle: vehicle,
        avatar: avatar,
        size: size,
        avatarImageBuilder: avatarImageBuilder,
      );
    }

    return Image.asset(
      vehicle.selectionImagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Text(
            vehicle.emoji,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(fontSize: 40, height: 1),
          ),
        );
      },
    );
  }
}
