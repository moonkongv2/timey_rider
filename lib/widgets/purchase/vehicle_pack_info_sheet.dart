import 'package:flutter/material.dart';

import '../../catalogs/vehicle_catalog.dart';
import '../../l10n/app_texts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../app/app_bouncy_button.dart';

typedef VehiclePackInfoPresenter =
    Future<bool> Function(BuildContext context, {required String vehicleId});

Future<bool> showVehiclePackInfoSheet(
  BuildContext context, {
  required String vehicleId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => VehiclePackInfoSheet(vehicleId: vehicleId),
  );

  return result ?? false;
}

class VehiclePackInfoSheet extends StatelessWidget {
  const VehiclePackInfoSheet({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final purchaseTexts = texts.purchase;
    final textTheme = Theme.of(context).textTheme;
    final vehicle = VehicleCatalog.findById(vehicleId);
    final vehicleLabel = vehicle.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );

    return DecoratedBox(
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
                    color: AppColors.accentBlueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Icon(
                      Icons.lock_rounded,
                      color: AppColors.blueDeep,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                purchaseTexts.vehiclePackInfoTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                purchaseTexts.vehiclePackInfoSubtitle(vehicleLabel),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              purchaseTexts.vehiclePackInfoUnlockAllMessage,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.38,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.family_restroom_rounded,
                            color: AppColors.brown500,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              purchaseTexts.vehiclePackInfoGuardianNote,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppBouncyButton(
                key: const ValueKey('vehiclePackInfoContinueButton'),
                label: purchaseTexts.vehiclePackInfoContinueButton,
                icon: Icons.family_restroom_rounded,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(purchaseTexts.vehiclePackInfoCloseButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
