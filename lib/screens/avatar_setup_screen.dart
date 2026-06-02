import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalogs/avatar_prompt_catalog.dart';
import '../catalogs/vehicle_catalog.dart';
import '../models/meal_timer_config.dart';
import '../models/vehicle.dart';
import '../services/avatar_image_picker.dart';
import '../services/local_avatar_image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/avatar/avatar_composite_preview.dart';
import '../widgets/vehicle_selection_card.dart';

class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.imagePicker,
    this.avatarImageService,
  });

  final MealTimerConfig config;
  final ValueChanged<MealTimerConfig> onConfigChanged;
  final AvatarImagePicker? imagePicker;
  final LocalAvatarImageService? avatarImageService;

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  late MealTimerConfig _config = widget.config;
  late AvatarImageMode _avatarMode = _avatarModeForConfig(widget.config);
  String? _pendingAvatarImagePath;
  late double _avatarScale = _avatarConfigForVehicle(widget.config).scale;
  late double _avatarOffsetX = _avatarConfigForVehicle(widget.config).offsetX;
  late double _avatarOffsetY = _avatarConfigForVehicle(widget.config).offsetY;
  late double _avatarRotationDegrees = _avatarConfigForVehicle(
    widget.config,
  ).rotationDegrees;
  bool _isUploadingAvatar = false;
  static const _guideItems = [
    '아이 얼굴이 잘 보이는 정면 사진을 사용해 주세요.',
    '얼굴이 크고 선명할수록 좋아요.',
    '모자, 마스크, 손 등으로 얼굴이 많이 가려진 사진은 피해주세요.',
    '생성 결과는 정사각형 1:1 이미지가 좋아요.',
    '배경은 투명하거나 단순한 배경이면 좋아요.',
    '텍스트, 로고, 워터마크는 없어야 해요.',
  ];

  @override
  void didUpdateWidget(covariant AvatarSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _config = widget.config;
    }
    final avatarConfigChanged =
        oldWidget.config.motorcycleId != widget.config.motorcycleId ||
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

  void _updateConfig(MealTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  AvatarImageMode _avatarModeForConfig(MealTimerConfig config) {
    return config.avatarModeForVehicle(config.motorcycleId);
  }

  VehicleAvatarConfig _avatarConfigForVehicle(MealTimerConfig config) {
    return config.customAvatarConfigForVehicle(config.motorcycleId) ??
        const VehicleAvatarConfig(
          imagePath: '',
          scale: 1.0,
          offsetX: 0.0,
          offsetY: 0.0,
          rotationDegrees: 0.0,
        );
  }

  String get _avatarModeLabel {
    return switch (_avatarMode) {
      AvatarImageMode.defaultImage => '기본 이미지 사용',
      AvatarImageMode.custom => '직접 만든 아바타 사용',
    };
  }

  String? get _selectedAvatarImagePath {
    final pendingPath = _pendingAvatarImagePath;
    if (pendingPath != null && pendingPath.trim().isNotEmpty) {
      return pendingPath;
    }

    final savedPath = _config.customAvatarImagePathForVehicle(
      _config.motorcycleId,
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
      const SnackBar(content: Text('프롬프트를 복사했어요. 외부 AI 서비스에 붙여넣어 사용해 주세요.')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아바타 이미지를 저장하지 못했어요.')));
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
          ..[_config.motorcycleId] = VehicleAvatarConfig(
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
        customAvatarVehicleId: _config.motorcycleId,
        avatarScale: _avatarScale,
        avatarOffsetX: _avatarOffsetX,
        avatarOffsetY: _avatarOffsetY,
        avatarRotationDegrees: _avatarRotationDegrees,
        customAvatarsByVehicle: nextAvatarsByVehicle,
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('아바타를 저장했어요.')));
  }

  void _useDefaultAvatarImage() {
    final nextAvatarsByVehicle = Map<String, VehicleAvatarConfig>.from(
      _config.customAvatarsByVehicle,
    )..remove(_config.motorcycleId);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기본 이미지로 변경했어요.')));
  }

  void _handleVehicleSelected(String vehicleId) {
    final nextConfig = _config.copyWith(motorcycleId: vehicleId);
    final nextAvatarConfig = _avatarConfigForVehicle(nextConfig);
    final nextAvatarMode = _avatarModeForConfig(nextConfig);
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vehicle = VehicleCatalog.findById(_config.motorcycleId);
    final vehicleLabel = vehicle.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final prompt = AvatarPromptCatalog.promptForVehicle(
      vehicle,
      Localizations.localeOf(context).languageCode,
    );
    final previewAvatarImagePath = _selectedAvatarImagePath;
    final vehicleAvatarConfig = _config.customAvatarConfigForVehicle(
      _config.motorcycleId,
    );
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
        title: const Text('우리 아이 아바타 만들기'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.brown900,
        elevation: 0,
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
              '외부 AI 서비스에서 아이 사진을 귀여운 라이더 캐릭터로 만든 뒤 업로드해 주세요.',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.42,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _AvatarInfoCard(
              title: '현재 선택한 차량',
              value: vehicleLabel,
              icon: Icons.directions_car_filled_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _AvatarInfoCard(
              title: '현재 아바타 모드',
              value: _avatarModeLabel,
              icon: Icons.face_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),
            SegmentedButton<AvatarImageMode>(
              segments: const [
                ButtonSegment(
                  value: AvatarImageMode.defaultImage,
                  label: Text('기본 이미지 사용'),
                ),
                ButtonSegment(
                  value: AvatarImageMode.custom,
                  label: Text('직접 만든 아바타 사용'),
                ),
              ],
              selected: {_avatarMode},
              onSelectionChanged: (selected) {
                setState(() => _avatarMode = selected.first);
              },
            ),
            if (_avatarMode == AvatarImageMode.custom) ...[
              const SizedBox(height: AppSpacing.xl),
              _AvatarUploadCard(
                imagePath: hasPreviewAvatarImage
                    ? previewAvatarImagePath
                    : null,
                isUploading: _isUploadingAvatar,
                onUploadPressed: _pickAvatarImage,
              ),
              const SizedBox(height: AppSpacing.md),
              if (shouldShowMissingAvatarWarning) ...[
                const _AvatarWarningCard(
                  message: '아바타 이미지를 찾을 수 없어 기본 이미지로 보여드려요.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (shouldShowCompositePreview) ...[
                _AvatarCompositePreviewCard(
                  vehicle: vehicle,
                  imagePath: previewAvatarImagePath,
                  avatarScale: _avatarScale,
                  avatarOffsetX: _avatarOffsetX,
                  avatarOffsetY: _avatarOffsetY,
                  avatarRotationDegrees: _avatarRotationDegrees,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _AvatarAdjustmentCard(
                hasImagePath: shouldShowCompositePreview,
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
                onConfirmPressed: shouldShowCompositePreview
                    ? _confirmCustomAvatar
                    : null,
                onUseDefaultPressed: _useDefaultAvatarImage,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xl),
              _DefaultAvatarPreviewCard(
                vehicle: vehicle,
                onUseDefaultPressed: _useDefaultAvatarImage,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            VehicleSelectionCard(
              title: '아바타를 태울 차량',
              subtitle: '프롬프트 기준',
              selectedVehicleId: _config.motorcycleId,
              onVehicleSelected: _handleVehicleSelected,
              avatarMode: _avatarMode,
              customAvatarImagePath: previewAvatarImagePath,
              avatarScale: vehicleAvatarConfig?.scale ?? _avatarScale,
              avatarOffsetX: vehicleAvatarConfig?.offsetX ?? _avatarOffsetX,
              avatarOffsetY: vehicleAvatarConfig?.offsetY ?? _avatarOffsetY,
              avatarRotationDegrees:
                  vehicleAvatarConfig?.rotationDegrees ??
                  _avatarRotationDegrees,
            ),
            if (_avatarMode == AvatarImageMode.custom) ...[
              const SizedBox(height: AppSpacing.xl),
              const _AvatarGuideCard(items: _guideItems),
              const SizedBox(height: AppSpacing.md),
              _AvatarPromptCard(
                prompt: prompt,
                onCopyPressed: () => _copyPrompt(prompt),
              ),
              const SizedBox(height: AppSpacing.md),
              const _AvatarPrivacyNoteCard(),
              const SizedBox(height: AppSpacing.md),
              if (!shouldShowCompositePreview)
                const _AvatarSetupStepCard(
                  title: '합성 미리보기',
                  icon: Icons.preview_rounded,
                ),
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
    required this.imagePath,
    required this.avatarScale,
    required this.avatarOffsetX,
    required this.avatarOffsetY,
    required this.avatarRotationDegrees,
  });

  final VehicleDefinition vehicle;
  final String imagePath;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_rounded, color: AppColors.brown700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '합성 미리보기',
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
              '이 모습으로 냠냠라이더를 탈까요?',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AvatarCompositePreview(
                vehicle: vehicle,
                avatarMode: AvatarImageMode.custom,
                customAvatarImagePath: imagePath,
                avatarScale: avatarScale,
                avatarOffsetX: avatarOffsetX,
                avatarOffsetY: avatarOffsetY,
                avatarRotationDegrees: avatarRotationDegrees,
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
                    '기본 이미지 미리보기',
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
                avatarMode: AvatarImageMode.defaultImage,
                customAvatarImagePath: null,
                avatarScale: 1.0,
                avatarOffsetX: 0.0,
                avatarOffsetY: 0.0,
                avatarRotationDegrees: 0.0,
                size: 180,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('avatarUseDefaultButton'),
              onPressed: onUseDefaultPressed,
              icon: const Icon(Icons.image_rounded),
              label: const Text('기본 이미지로 사용하기'),
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
    required this.hasImagePath,
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

  final bool hasImagePath;
  final double avatarScale;
  final double avatarOffsetX;
  final double avatarOffsetY;
  final double avatarRotationDegrees;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onOffsetXChanged;
  final ValueChanged<double> onOffsetYChanged;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback onResetPressed;
  final VoidCallback? onConfirmPressed;
  final VoidCallback onUseDefaultPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                    '아바타 위치 조정',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (hasImagePath) ...[
              const SizedBox(height: AppSpacing.md),
              _AvatarAdjustmentSlider(
                label: '얼굴 크기',
                value: avatarScale,
                min: 0.7,
                max: 2.0,
                divisions: 26,
                keyValue: 'avatarScaleSlider',
                onChanged: onScaleChanged,
              ),
              _AvatarAdjustmentSlider(
                label: '좌우 위치',
                value: avatarOffsetX,
                min: -0.2,
                max: 0.2,
                divisions: 16,
                keyValue: 'avatarOffsetXSlider',
                onChanged: onOffsetXChanged,
              ),
              _AvatarAdjustmentSlider(
                label: '위아래 위치',
                value: avatarOffsetY,
                min: -0.2,
                max: 0.2,
                divisions: 16,
                keyValue: 'avatarOffsetYSlider',
                onChanged: onOffsetYChanged,
              ),
              _AvatarAdjustmentSlider(
                label: '기울기',
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
                label: const Text('위치 초기화'),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '아바타 이미지를 업로드하면 얼굴 크기와 위치를 조정할 수 있어요.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.36,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('avatarConfirmButton'),
              onPressed: onConfirmPressed,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('이 아바타로 사용하기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const ValueKey('avatarUseDefaultButton'),
              onPressed: onUseDefaultPressed,
              icon: const Icon(Icons.image_rounded),
              label: const Text('기본 이미지로 사용하기'),
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
  const _AvatarGuideCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                    '이미지 생성 가이드',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in items) ...[
              _GuideBullet(text: item),
              if (item != items.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.orangeDeep,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.34,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarPromptCard extends StatelessWidget {
  const _AvatarPromptCard({required this.prompt, required this.onCopyPressed});

  final String prompt;
  final VoidCallback onCopyPressed;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.content_copy_rounded,
                  color: AppColors.brown700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '프롬프트 복사',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
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
                  prompt,
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
              onPressed: onCopyPressed,
              icon: const Icon(Icons.content_copy_rounded),
              label: const Text('프롬프트 복사하기'),
            ),
          ],
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
  });

  final String? imagePath;
  final bool isUploading;
  final VoidCallback onUploadPressed;

  bool get _hasImagePath => imagePath != null && imagePath!.trim().isNotEmpty;

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
                    '아바타 이미지 업로드',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_hasImagePath)
              _AvatarImagePreview(imagePath: imagePath!)
            else
              Text(
                '생성형 AI에서 만든 정사각형 아바타 이미지를 업로드해 주세요.\n'
                '얼굴이 중앙에 있고 배경이 단순할수록 좋아요.',
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
                    ? '업로드 중'
                    : _hasImagePath
                    ? '다시 업로드'
                    : '아바타 이미지 업로드',
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
                  '선택한 아바타 이미지',
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
                '앱이 직접 AI 이미지를 생성하거나 아이 사진을 업로드하지는 않아요.\n'
                '사용자가 선택한 외부 AI 서비스에서 이미지를 만든 뒤, 완성된 아바타 이미지만 냠냠라이더에 업로드해 주세요.\n'
                '외부 서비스 이용 전 사진/개인정보 처리 방침을 확인해 주세요.',
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

class _AvatarSetupStepCard extends StatelessWidget {
  const _AvatarSetupStepCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.82),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brown700),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
