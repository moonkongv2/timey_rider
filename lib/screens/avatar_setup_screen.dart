import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalogs/avatar_prompt_catalog.dart';
import '../catalogs/vehicle_catalog.dart';
import '../catalogs/vehicle_unlock_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/activity_timer_config.dart';
import '../models/vehicle.dart';
import '../models/vehicle_avatar_presentation.dart';
import '../services/avatar_image_picker.dart';
import '../services/local_avatar_image_service.dart';
import '../services/vehicle_pack_purchase_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/avatar/avatar_composite_preview.dart';
import '../widgets/avatar/rider_guide_bottom_sheet.dart';
import '../widgets/vehicle_selection_card.dart';

class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.imagePicker,
    this.avatarImageService,
    this.purchaseController,
    this.purchaseState = const VehiclePackPurchaseState.initial(),
  });

  final ActivityTimerConfig config;
  final ValueChanged<ActivityTimerConfig> onConfigChanged;
  final AvatarImagePicker? imagePicker;
  final LocalAvatarImageService? avatarImageService;
  final VehiclePackPurchaseController? purchaseController;
  final VehiclePackPurchaseState purchaseState;

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  late ActivityTimerConfig _config = widget.config;
  late AvatarImageMode _avatarMode = _avatarModeForConfig(widget.config);
  String? _pendingAvatarImagePath;
  late double _avatarScale = _avatarConfigForVehicle(widget.config).scale;
  late double _avatarOffsetX = _avatarConfigForVehicle(widget.config).offsetX;
  late double _avatarOffsetY = _avatarConfigForVehicle(widget.config).offsetY;
  late double _avatarRotationDegrees = _avatarConfigForVehicle(
    widget.config,
  ).rotationDegrees;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRiderGuide();
    });
  }

  void _showRiderGuide() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const RiderGuideBottomSheet(),
    );
  }

  @override
  void didUpdateWidget(covariant AvatarSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _config = widget.config;
    }
    final avatarConfigChanged =
        oldWidget.config.vehicleId != widget.config.vehicleId ||
        oldWidget.config.avatarMode != widget.config.avatarMode ||
        oldWidget.config.customAvatarImagePath !=
            widget.config.customAvatarImagePath ||
        oldWidget.config.customAvatarVehicleId !=
            widget.config.customAvatarVehicleId ||
        oldWidget.config.customAvatarsByVehicle !=
            widget.config.customAvatarsByVehicle ||
        oldWidget.config.avatarScale != widget.config.avatarScale ||
        oldWidget.config.avatarOffsetX != widget.config.avatarOffsetX ||
        oldWidget.config.avatarOffsetY != widget.config.avatarOffsetY ||
        oldWidget.config.avatarRotationDegrees !=
            widget.config.avatarRotationDegrees;
    if (avatarConfigChanged) {
      final avatarConfig = _avatarConfigForVehicle(widget.config);
      _avatarMode = _avatarModeForConfig(widget.config);
      _pendingAvatarImagePath = null;
      _avatarScale = avatarConfig.scale;
      _avatarOffsetX = avatarConfig.offsetX;
      _avatarOffsetY = avatarConfig.offsetY;
      _avatarRotationDegrees = avatarConfig.rotationDegrees;
    }
  }

  void _updateConfig(ActivityTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  AvatarImageMode _avatarModeForConfig(ActivityTimerConfig config) {
    return config.avatarModeForVehicle(config.vehicleId);
  }

  VehicleAvatarConfig _avatarConfigForVehicle(ActivityTimerConfig config) {
    return config.customAvatarConfigForVehicle(config.vehicleId) ??
        const VehicleAvatarConfig(
          imagePath: '',
          scale: 1.0,
          offsetX: 0.0,
          offsetY: 0.0,
          rotationDegrees: 0.0,
        );
  }

  VehicleAvatarPresentation _currentEditingAvatarPresentation() {
    final imagePath = _selectedAvatarImagePath;
    if (_avatarMode == AvatarImageMode.custom &&
        imagePath != null &&
        imagePath.trim().isNotEmpty) {
      return VehicleAvatarPresentation(
        mode: AvatarImageMode.custom,
        imagePath: imagePath,
        scale: _avatarScale,
        offsetX: _avatarOffsetX,
        offsetY: _avatarOffsetY,
        rotationDegrees: _avatarRotationDegrees,
      );
    }

    return VehicleAvatarPresentation.defaultImage;
  }

  VehicleAvatarPresentation? _avatarPresentationForVehicleChoice(
    String vehicleId,
  ) {
    if (vehicleId == _config.vehicleId &&
        _avatarMode == AvatarImageMode.custom) {
      return _currentEditingAvatarPresentation();
    }

    return _config.avatarPresentationForVehicle(vehicleId);
  }

  bool get _shouldApplyVehicleLocks {
    return widget.purchaseController != null;
  }

  bool _isVehicleLocked(String vehicleId) {
    return _shouldApplyVehicleLocks &&
        !VehicleUnlockCatalog.isVehicleUnlocked(
          vehicleId,
          widget.purchaseState.entitlement,
        );
  }

  String _avatarModeLabel(BuildContext context) {
    final texts = AppTexts.of(context).avatarSetup;
    return switch (_avatarMode) {
      AvatarImageMode.defaultImage => texts.defaultImageMode,
      AvatarImageMode.custom => texts.customAvatarMode,
    };
  }

  String? get _selectedAvatarImagePath {
    final pendingPath = _pendingAvatarImagePath;
    if (pendingPath != null && pendingPath.trim().isNotEmpty) {
      return pendingPath;
    }

    final savedPath = _config.customAvatarImagePathForVehicle(
      _config.vehicleId,
    );
    if (savedPath != null && savedPath.trim().isNotEmpty) {
      return savedPath;
    }

    return null;
  }

  Future<void> _copyPrompt(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTexts.of(context).avatarSetup.copyPromptMessage),
      ),
    );
  }

  Future<void> _pickAvatarImage() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final pickedFile =
          await (widget.imagePicker ?? DefaultAvatarImagePicker())
              .pickAvatarImage();
      if (pickedFile == null) {
        return;
      }

      final savedPath =
          await (widget.avatarImageService ?? const LocalAvatarImageService())
              .savePickedAvatarImage(pickedFile);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarMode = AvatarImageMode.custom;
        _pendingAvatarImagePath = savedPath;
      });
    } catch (error, stackTrace) {
      debugPrint('Avatar image upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTexts.of(context).avatarSetup.avatarSaveFailureMessage,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _resetAvatarAdjustment() {
    setState(() {
      _avatarScale = 1.0;
      _avatarOffsetX = 0.0;
      _avatarOffsetY = 0.0;
      _avatarRotationDegrees = 0.0;
    });
  }

  void _confirmCustomAvatar() {
    final selectedPath = _selectedAvatarImagePath;
    if (selectedPath == null) {
      return;
    }

    final nextAvatarsByVehicle =
        Map<String, VehicleAvatarConfig>.from(_config.customAvatarsByVehicle)
          ..[_config.vehicleId] = VehicleAvatarConfig(
            imagePath: selectedPath,
            scale: _avatarScale,
            offsetX: _avatarOffsetX,
            offsetY: _avatarOffsetY,
            rotationDegrees: _avatarRotationDegrees,
          );
    setState(() => _avatarMode = AvatarImageMode.custom);
    _updateConfig(
      _config.copyWith(
        avatarMode: AvatarImageMode.custom,
        customAvatarImagePath: selectedPath,
        customAvatarVehicleId: _config.vehicleId,
        avatarScale: _avatarScale,
        avatarOffsetX: _avatarOffsetX,
        avatarOffsetY: _avatarOffsetY,
        avatarRotationDegrees: _avatarRotationDegrees,
        customAvatarsByVehicle: nextAvatarsByVehicle,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTexts.of(context).avatarSetup.avatarSavedMessage),
      ),
    );
  }

  void _useDefaultAvatarImage() {
    final nextAvatarsByVehicle = Map<String, VehicleAvatarConfig>.from(
      _config.customAvatarsByVehicle,
    )..remove(_config.vehicleId);
    setState(() => _avatarMode = AvatarImageMode.defaultImage);
    _updateConfig(
      _config.copyWith(
        avatarMode: nextAvatarsByVehicle.isEmpty
            ? AvatarImageMode.defaultImage
            : AvatarImageMode.custom,
        customAvatarImagePath: null,
        customAvatarVehicleId: null,
        avatarScale: 1.0,
        avatarOffsetX: 0.0,
        avatarOffsetY: 0.0,
        avatarRotationDegrees: 0.0,
        customAvatarsByVehicle: nextAvatarsByVehicle,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppTexts.of(context).avatarSetup.defaultImageSavedMessage,
        ),
      ),
    );
  }

  void _handleVehicleSelected(String vehicleId) {
    if (_isVehicleLocked(vehicleId)) {
      return;
    }

    final nextConfig = _config.copyWith(vehicleId: vehicleId);
    final nextAvatarConfig = _avatarConfigForVehicle(nextConfig);
    final nextAvatarMode = _avatarMode == AvatarImageMode.custom
        ? AvatarImageMode.custom
        : _avatarModeForConfig(nextConfig);
    setState(() {
      _config = nextConfig;
      _avatarMode = nextAvatarMode;
      _pendingAvatarImagePath = null;
      _avatarScale = nextAvatarConfig.scale;
      _avatarOffsetX = nextAvatarConfig.offsetX;
      _avatarOffsetY = nextAvatarConfig.offsetY;
      _avatarRotationDegrees = nextAvatarConfig.rotationDegrees;
    });
    widget.onConfigChanged(nextConfig);
  }

  void _handleLockedVehiclePressed(String _) {
    // Guardian gate and purchase UI are wired in the next commits.
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;
    final vehicle = VehicleCatalog.findById(_config.vehicleId);
    final vehicleLabel = vehicle.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final prompt = AvatarPromptCatalog.promptForVehicle(
      vehicle,
      Localizations.localeOf(context).languageCode,
    );
    final previewAvatarImagePath = _selectedAvatarImagePath;
    final currentEditingAvatar = _currentEditingAvatarPresentation();
    final hasPreviewAvatarImage =
        previewAvatarImagePath != null &&
        File(previewAvatarImagePath).existsSync();
    final shouldShowMissingAvatarWarning =
        _avatarMode == AvatarImageMode.custom &&
        previewAvatarImagePath != null &&
        !hasPreviewAvatarImage;
    final shouldShowCompositePreview =
        _avatarMode == AvatarImageMode.custom && hasPreviewAvatarImage;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(texts.title),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.brown900,
        elevation: 0,
        actions: [
          IconButton(
            key: const ValueKey('avatarGuideReplayButton'),
            onPressed: _showRiderGuide,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: texts.guideReplayTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              texts.intro,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.42,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _AvatarInfoCard(
              title: texts.selectedVehicleTitle,
              value: vehicleLabel,
              icon: Icons.directions_car_filled_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _AvatarInfoCard(
              title: texts.currentAvatarModeTitle,
              value: _avatarModeLabel(context),
              icon: Icons.face_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),
            SegmentedButton<AvatarImageMode>(
              segments: [
                ButtonSegment(
                  value: AvatarImageMode.defaultImage,
                  label: Text(texts.defaultImageMode),
                ),
                ButtonSegment(
                  value: AvatarImageMode.custom,
                  label: Text(texts.customAvatarMode),
                ),
              ],
              selected: {_avatarMode},
              onSelectionChanged: (selected) {
                setState(() => _avatarMode = selected.first);
              },
            ),
            if (_avatarMode == AvatarImageMode.custom) ...[
              const SizedBox(height: AppSpacing.xl),
              VehicleSelectionCard(
                title: texts.vehicleSelectionTitle,
                subtitle: texts.vehicleSelectionSubtitle,
                selectedVehicleId: _config.vehicleId,
                onVehicleSelected: _handleVehicleSelected,
                isVehicleLocked: _shouldApplyVehicleLocks
                    ? _isVehicleLocked
                    : null,
                onLockedVehiclePressed: _shouldApplyVehicleLocks
                    ? _handleLockedVehiclePressed
                    : null,
                avatar: currentEditingAvatar,
                avatarForVehicle: _avatarPresentationForVehicleChoice,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _AvatarGuideCard(),
              const SizedBox(height: AppSpacing.md),
              _AvatarPromptCard(
                prompt: prompt,
                onCopyPressed: () => _copyPrompt(prompt),
              ),
              const SizedBox(height: AppSpacing.md),
              _AvatarUploadCard(
                imagePath: hasPreviewAvatarImage
                    ? previewAvatarImagePath
                    : null,
                isUploading: _isUploadingAvatar,
                onUploadPressed: _pickAvatarImage,
                onGuidePressed: _showRiderGuide,
              ),
              const SizedBox(height: AppSpacing.md),
              if (shouldShowMissingAvatarWarning) ...[
                _AvatarWarningCard(message: texts.missingAvatarWarning),
                const SizedBox(height: AppSpacing.md),
              ],
              if (shouldShowCompositePreview) ...[
                _AvatarCompositePreviewCard(
                  vehicle: vehicle,
                  avatar: currentEditingAvatar,
                ),
                const SizedBox(height: AppSpacing.md),
                _AvatarAdjustmentCard(
                  avatarScale: _avatarScale,
                  avatarOffsetX: _avatarOffsetX,
                  avatarOffsetY: _avatarOffsetY,
                  avatarRotationDegrees: _avatarRotationDegrees,
                  onScaleChanged: (value) {
                    setState(() => _avatarScale = value);
                  },
                  onOffsetXChanged: (value) {
                    setState(() => _avatarOffsetX = value);
                  },
                  onOffsetYChanged: (value) {
                    setState(() => _avatarOffsetY = value);
                  },
                  onRotationChanged: (value) {
                    setState(() => _avatarRotationDegrees = value);
                  },
                  onResetPressed: _resetAvatarAdjustment,
                  onConfirmPressed: _confirmCustomAvatar,
                  onUseDefaultPressed: _useDefaultAvatarImage,
                ),
              ],
            ] else ...[
              const SizedBox(height: AppSpacing.xl),
              _DefaultAvatarPreviewCard(
                vehicle: vehicle,
                onUseDefaultPressed: _useDefaultAvatarImage,
              ),
              const SizedBox(height: AppSpacing.xl),
              VehicleSelectionCard(
                title: texts.vehicleSelectionTitle,
                subtitle: texts.vehicleSelectionSubtitle,
                selectedVehicleId: _config.vehicleId,
                onVehicleSelected: _handleVehicleSelected,
                isVehicleLocked: _shouldApplyVehicleLocks
                    ? _isVehicleLocked
                    : null,
                onLockedVehiclePressed: _shouldApplyVehicleLocks
                    ? _handleLockedVehiclePressed
                    : null,
                avatar: currentEditingAvatar,
                avatarForVehicle: _avatarPresentationForVehicleChoice,
              ),
            ],
            if (_avatarMode == AvatarImageMode.custom) ...[
              const SizedBox(height: AppSpacing.md),
              const _AvatarPrivacyNoteCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarCompositePreviewCard extends StatelessWidget {
  const _AvatarCompositePreviewCard({
    required this.vehicle,
    required this.avatar,
  });

  final VehicleDefinition vehicle;
  final VehicleAvatarPresentation avatar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;

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
                const Icon(Icons.preview_rounded, color: AppColors.brown700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    texts.compositePreviewTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              texts.compositePreviewSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AvatarCompositePreview(
                vehicle: vehicle,
                avatar: avatar,
                size: 220,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultAvatarPreviewCard extends StatelessWidget {
  const _DefaultAvatarPreviewCard({
    required this.vehicle,
    required this.onUseDefaultPressed,
  });

  final VehicleDefinition vehicle;
  final VoidCallback onUseDefaultPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.image_rounded, color: AppColors.brown700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    texts.defaultPreviewTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AvatarCompositePreview(
                vehicle: vehicle,
                avatar: VehicleAvatarPresentation.defaultImage,
                size: 180,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('avatarUseDefaultButton'),
              onPressed: onUseDefaultPressed,
              icon: const Icon(Icons.image_rounded),
              label: Text(texts.useDefaultImageButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWarningCard extends StatelessWidget {
  const _AvatarWarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceYellow.withValues(alpha: 0.52),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.brown700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarAdjustmentCard extends StatelessWidget {
  const _AvatarAdjustmentCard({
    required this.avatarScale,
    required this.avatarOffsetX,
    required this.avatarOffsetY,
    required this.avatarRotationDegrees,
    required this.onScaleChanged,
    required this.onOffsetXChanged,
    required this.onOffsetYChanged,
    required this.onRotationChanged,
    required this.onResetPressed,
    required this.onConfirmPressed,
    required this.onUseDefaultPressed,
  });

  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onOffsetXChanged;
  final ValueChanged<double> onOffsetYChanged;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback onResetPressed;
  final VoidCallback onConfirmPressed;
  final VoidCallback onUseDefaultPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.86),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.brown700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    texts.adjustmentTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _AvatarAdjustmentSlider(
              label: texts.faceSizeLabel,
              value: avatarScale,
              min: 0.7,
              max: 2.0,
              divisions: 26,
              keyValue: 'avatarScaleSlider',
              onChanged: onScaleChanged,
            ),
            _AvatarAdjustmentSlider(
              label: texts.horizontalPositionLabel,
              value: avatarOffsetX,
              min: -0.2,
              max: 0.2,
              divisions: 16,
              keyValue: 'avatarOffsetXSlider',
              onChanged: onOffsetXChanged,
            ),
            _AvatarAdjustmentSlider(
              label: texts.verticalPositionLabel,
              value: -avatarOffsetY,
              min: -0.2,
              max: 0.2,
              divisions: 16,
              keyValue: 'avatarOffsetYSlider',
              onChanged: (value) => onOffsetYChanged(-value),
            ),
            _AvatarAdjustmentSlider(
              label: texts.rotationLabel,
              value: avatarRotationDegrees,
              min: -15,
              max: 15,
              divisions: 30,
              keyValue: 'avatarRotationSlider',
              onChanged: onRotationChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const ValueKey('avatarResetButton'),
              onPressed: onResetPressed,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(texts.resetPositionButton),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('avatarConfirmButton'),
              onPressed: onConfirmPressed,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(texts.confirmAvatarButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const ValueKey('avatarUseDefaultButton'),
              onPressed: onUseDefaultPressed,
              icon: const Icon(Icons.image_rounded),
              label: Text(texts.useDefaultImageButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarAdjustmentSlider extends StatelessWidget {
  const _AvatarAdjustmentSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.keyValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String keyValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          key: ValueKey(keyValue),
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AvatarGuideCard extends StatelessWidget {
  const _AvatarGuideCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.86),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.brown700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    texts.guideTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              texts.guideIntro,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.34,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _GuideMethod(
              title: texts.guidePopupMethod1Title,
              body: texts.guidePopupMethod1Body,
              icon: Icons.photo_library_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _GuideMethod(
              title: texts.guidePopupMethod2Title,
              body: texts.guidePopupMethod2Body,
              icon: Icons.auto_fix_high_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PromptGuideHint(text: texts.promptGuideHint),
          ],
        ),
      ),
    );
  }
}

class _PromptGuideHint extends StatelessWidget {
  const _PromptGuideHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.brown700,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.brown700,
              fontWeight: FontWeight.w700,
              height: 1.32,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideMethod extends StatelessWidget {
  const _GuideMethod({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: AppColors.orangeDeep, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.34,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarPromptCard extends StatefulWidget {
  const _AvatarPromptCard({required this.prompt, required this.onCopyPressed});

  final String prompt;
  final VoidCallback onCopyPressed;

  @override
  State<_AvatarPromptCard> createState() => _AvatarPromptCardState();
}

class _AvatarPromptCardState extends State<_AvatarPromptCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;
    final toggleLabel = _isExpanded
        ? texts.promptCollapseLabel
        : texts.promptExpandLabel;

    return Material(
      color: AppColors.surfaceWarm,
      borderRadius: AppRadius.card,
      child: InkWell(
        key: const ValueKey('avatarPromptToggle'),
        onTap: _toggleExpanded,
        borderRadius: AppRadius.card,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: AppShadows.surface,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: '${texts.promptToggleSemanticLabel}, $toggleLabel',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.content_copy_rounded,
                        color: AppColors.brown700,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              texts.promptCopyTitle,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.textStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              texts.promptHelperText,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                height: 1.34,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.brown700,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.78),
                    borderRadius: AppRadius.compactCard,
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SelectableText(
                      key: const ValueKey('avatarPromptText'),
                      widget.prompt,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const ValueKey('avatarPromptCopyButton'),
                  onPressed: widget.onCopyPressed,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text(texts.copyPromptButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarUploadCard extends StatelessWidget {
  const _AvatarUploadCard({
    required this.imagePath,
    required this.isUploading,
    required this.onUploadPressed,
    required this.onGuidePressed,
  });

  final String? imagePath;
  final bool isUploading;
  final VoidCallback onUploadPressed;
  final VoidCallback onGuidePressed;

  bool get _hasImagePath => imagePath != null && imagePath!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final texts = AppTexts.of(context).avatarSetup;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.brown700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    texts.uploadTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('avatarUploadGuideButton'),
                  onPressed: onGuidePressed,
                  icon: const Icon(Icons.info_outline_rounded),
                  color: AppColors.primary,
                  tooltip: texts.guidePopupTitle,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_hasImagePath)
              _AvatarImagePreview(imagePath: imagePath!)
            else
              Text(
                texts.uploadInstructions,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: isUploading ? null : onUploadPressed,
              icon: Icon(
                _hasImagePath
                    ? Icons.refresh_rounded
                    : Icons.upload_file_rounded,
              ),
              label: Text(
                isUploading
                    ? texts.uploadingButton
                    : _hasImagePath
                    ? texts.reuploadButton
                    : texts.uploadButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarImagePreview extends StatelessWidget {
  const _AvatarImagePreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: AppRadius.compactCard,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.76),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Image.file(
            File(imagePath),
            key: const ValueKey('pendingAvatarImagePreview'),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  AppTexts.of(context).avatarSetup.selectedImageFallback,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AvatarPrivacyNoteCard extends StatelessWidget {
  const _AvatarPrivacyNoteCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceBlue.withValues(alpha: 0.42),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.privacy_tip_rounded, color: AppColors.brown700),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                AppTexts.of(context).avatarSetup.privacyNote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarInfoCard extends StatelessWidget {
  const _AvatarInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceYellow.withValues(alpha: 0.72),
                borderRadius: AppRadius.pill,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: AppColors.brown700),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
