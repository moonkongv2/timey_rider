import 'package:flutter/material.dart';

import '../../l10n/app_texts.dart';
import '../../services/vehicle_pack_purchase_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../app/app_bouncy_button.dart';

typedef VehiclePackPurchasePresenter =
    Future<void> Function(
      BuildContext context, {
      required VehiclePackPurchaseController controller,
      required String vehicleId,
    });

Future<void> showVehiclePackPurchaseSheet(
  BuildContext context, {
  required VehiclePackPurchaseController controller,
  required String vehicleId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    builder: (_) =>
        VehiclePackPurchaseSheet(controller: controller, vehicleId: vehicleId),
  );
}

class VehiclePackPurchaseSheet extends StatefulWidget {
  const VehiclePackPurchaseSheet({
    super.key,
    required this.controller,
    required this.vehicleId,
  });

  final VehiclePackPurchaseController controller;
  final String vehicleId;

  @override
  State<VehiclePackPurchaseSheet> createState() =>
      _VehiclePackPurchaseSheetState();
}

class _VehiclePackPurchaseSheetState extends State<VehiclePackPurchaseSheet> {
  late VehiclePackPurchaseState _purchaseState = widget.controller.state;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePurchaseStateChanged);
    if (!_purchaseState.vehiclePackUnlocked && _purchaseState.product == null) {
      Future<void>.microtask(widget.controller.loadVehiclePackProduct);
    }
  }

  @override
  void didUpdateWidget(covariant VehiclePackPurchaseSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_handlePurchaseStateChanged);
    _purchaseState = widget.controller.state;
    widget.controller.addListener(_handlePurchaseStateChanged);
    if (!_purchaseState.vehiclePackUnlocked && _purchaseState.product == null) {
      Future<void>.microtask(widget.controller.loadVehiclePackProduct);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePurchaseStateChanged);
    super.dispose();
  }

  void _handlePurchaseStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _purchaseState = widget.controller.state);
  }

  Future<void> _buyVehiclePack() async {
    var product = _purchaseState.product;
    if (product == null) {
      product = await widget.controller.loadVehiclePackProduct();
      if (product == null) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    await widget.controller.buyVehiclePack(product: product);
  }

  Future<void> _restoreVehiclePack() async {
    await widget.controller.restoreVehiclePack();
  }

  bool get _isBusy {
    return switch (_purchaseState.status) {
      VehiclePackPurchaseStatus.loadingProduct ||
      VehiclePackPurchaseStatus.purchaseInProgress ||
      VehiclePackPurchaseStatus.pending ||
      VehiclePackPurchaseStatus.restoring => true,
      _ => false,
    };
  }

  bool get _canBuy {
    return !_isBusy && !_purchaseState.vehiclePackUnlocked;
  }

  bool get _canRestore {
    return !_isBusy && !_purchaseState.vehiclePackUnlocked;
  }

  String _statusMessage(BuildContext context) {
    final texts = AppTexts.of(context).purchase;
    if (_purchaseState.vehiclePackUnlocked) {
      return switch (_purchaseState.status) {
        VehiclePackPurchaseStatus.restored => texts.vehiclePackRestoredMessage,
        _ => texts.vehiclePackPurchasedMessage,
      };
    }

    return switch (_purchaseState.status) {
      VehiclePackPurchaseStatus.loadingProduct =>
        texts.vehiclePackPurchaseLoadingMessage,
      VehiclePackPurchaseStatus.productUnavailable =>
        texts.vehiclePackPurchaseUnavailableMessage,
      VehiclePackPurchaseStatus.purchaseInProgress =>
        texts.vehiclePackPurchaseInProgressMessage,
      VehiclePackPurchaseStatus.pending => texts.vehiclePackPendingMessage,
      VehiclePackPurchaseStatus.restoring => texts.vehiclePackRestoringMessage,
      VehiclePackPurchaseStatus.restoreNotFound =>
        texts.vehiclePackRestoreNotFoundMessage,
      VehiclePackPurchaseStatus.canceled => texts.vehiclePackCanceledMessage,
      VehiclePackPurchaseStatus.error => texts.vehiclePackErrorMessage,
      _ => texts.vehiclePackPurchaseSubtitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    final purchaseTexts = texts.purchase;
    final textTheme = Theme.of(context).textTheme;
    final product = _purchaseState.product;
    final price = product?.price;

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
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Icon(
                      _purchaseState.vehiclePackUnlocked
                          ? Icons.check_rounded
                          : Icons.local_taxi_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                purchaseTexts.vehiclePackPurchaseTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _statusMessage(context),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.42,
                ),
              ),
              if (price != null && !_purchaseState.vehiclePackUnlocked) ...[
                const SizedBox(height: AppSpacing.lg),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_open_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            purchaseTexts.vehiclePackPriceLabel(price),
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_isBusy) ...[
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (!_purchaseState.vehiclePackUnlocked) ...[
                AppBouncyButton(
                  key: const ValueKey('vehiclePackPurchaseButton'),
                  label: price == null
                      ? purchaseTexts.vehiclePackPurchaseButton
                      : '${purchaseTexts.vehiclePackPurchaseButton} $price',
                  icon: Icons.lock_open_rounded,
                  onPressed: _canBuy ? _buyVehiclePack : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppBouncyButton(
                  key: const ValueKey('vehiclePackRestoreButton'),
                  label: purchaseTexts.vehiclePackRestoreButton,
                  icon: Icons.restore_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: _canRestore ? _restoreVehiclePack : null,
                ),
              ] else
                AppBouncyButton(
                  key: const ValueKey('vehiclePackPurchaseDoneButton'),
                  label: texts.common.complete,
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
                child: Text(texts.common.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
