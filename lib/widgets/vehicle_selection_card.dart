import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

class VehicleSelectionCard extends StatelessWidget {
  const VehicleSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selectedVehicleId,
    required this.onVehicleSelected,
  });

  final String title;
  final String? subtitle;
  final String selectedVehicleId;
  final ValueChanged<String> onVehicleSelected;

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
                  DecoratedBox(
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.sm;
                final fourAcrossWidth =
                    (constraints.maxWidth - (spacing * 3)) / 4;
                final itemSize = fourAcrossWidth.clamp(72.0, 84.0).toDouble();
                final contentWidth =
                    (itemSize * VehicleCatalog.all.length) +
                    (spacing * (VehicleCatalog.all.length - 1));
                final rowWidth = math.max(constraints.maxWidth, contentWidth);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: rowWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (
                          var index = 0;
                          index < VehicleCatalog.all.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: spacing),
                          _VehicleChoiceButton(
                            size: itemSize,
                            vehicle: VehicleCatalog.all[index],
                            isSelected:
                                selectedVehicle.id ==
                                VehicleCatalog.all[index].id,
                            onTap: () =>
                                onVehicleSelected(VehicleCatalog.all[index].id),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
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
  });

  final double size;
  final VehicleDefinition vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primarySoft
        : AppColors.borderSoft;
    final backgroundColor = isSelected
        ? AppColors.surfaceYellow.withValues(alpha: 0.72)
        : AppColors.white.withValues(alpha: 0.72);
    final borderRadius = AppRadius.compactCard;

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
                    child: Image.asset(
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
