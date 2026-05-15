import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalogs/avatar_prompt_catalog.dart';
import '../catalogs/vehicle_catalog.dart';
import '../models/meal_timer_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/vehicle_selection_card.dart';

class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  final MealTimerConfig config;
  final ValueChanged<MealTimerConfig> onConfigChanged;

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  late MealTimerConfig _config = widget.config;
  late AvatarImageMode _avatarMode = widget.config.avatarMode;
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
      _avatarMode = widget.config.avatarMode;
    }
  }

  void _updateConfig(MealTimerConfig config) {
    setState(() => _config = config);
    widget.onConfigChanged(config);
  }

  String get _avatarModeLabel {
    return switch (_avatarMode) {
      AvatarImageMode.defaultImage => '기본 이미지 사용',
      AvatarImageMode.custom => '직접 만든 아바타 사용',
    };
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
            const SizedBox(height: AppSpacing.xl),
            VehicleSelectionCard(
              title: '아바타를 태울 차량',
              subtitle: '프롬프트 기준',
              selectedVehicleId: _config.motorcycleId,
              onVehicleSelected: (vehicleId) {
                _updateConfig(_config.copyWith(motorcycleId: vehicleId));
              },
            ),
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
            const _AvatarSetupStepCard(
              title: '아바타 이미지 업로드',
              icon: Icons.upload_file_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            const _AvatarSetupStepCard(
              title: '합성 미리보기',
              icon: Icons.preview_rounded,
            ),
          ],
        ),
      ),
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
