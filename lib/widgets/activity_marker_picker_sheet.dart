import 'package:flutter/material.dart';

import '../catalogs/activity_marker_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/activity_marker.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'app/app_help_sheet.dart';

sealed class ActivityMarkerPickerResult {
  const ActivityMarkerPickerResult();
}

class RandomActivityMarkers extends ActivityMarkerPickerResult {
  const RandomActivityMarkers();
}

class SelectedActivityMarkers extends ActivityMarkerPickerResult {
  SelectedActivityMarkers(List<String> markerIds)
    : markerIds = List.unmodifiable(markerIds);

  final List<String> markerIds;
}

class ActivityMarkerPickerSheet extends StatefulWidget {
  const ActivityMarkerPickerSheet({
    super.key,
    required this.activityId,
    this.initialSelectedIds = const [],
  });

  final String activityId;
  final List<String> initialSelectedIds;

  @override
  State<ActivityMarkerPickerSheet> createState() =>
      _ActivityMarkerPickerSheetState();
}

class _ActivityMarkerPickerSheetState extends State<ActivityMarkerPickerSheet> {
  late final Set<String> _selectedIds = _validInitialSelectedIds();

  late final List<ActivityMarkerDefinition> _availableMarkers =
      _markersForActivity();

  List<ActivityMarkerDefinition> _markersForActivity() {
    final activityMarkerIds = ActivityMarkerCatalog.markerIdsForActivity(
      widget.activityId,
    );
    final candidateIds = activityMarkerIds.isEmpty
        ? ActivityMarkerCatalog.defaultSelectionIds
        : activityMarkerIds;
    return List.unmodifiable(
      candidateIds.map(ActivityMarkerCatalog.findById).nonNulls,
    );
  }

  Set<String> _validInitialSelectedIds() {
    final selectedIds = <String>{};
    final availableIds = _availableMarkers.map((marker) => marker.id).toSet();
    for (final id in widget.initialSelectedIds) {
      if (selectedIds.length >=
          ActivityMarkerCatalog.maxSelectableMarkerCount) {
        break;
      }
      if (availableIds.contains(id)) {
        selectedIds.add(id);
      }
    }
    return selectedIds;
  }

  void _toggleMarker(ActivityMarkerDefinition marker) {
    setState(() {
      if (_selectedIds.contains(marker.id)) {
        _selectedIds.remove(marker.id);
        return;
      }
      if (_selectedIds.length <
          ActivityMarkerCatalog.maxSelectableMarkerCount) {
        _selectedIds.add(marker.id);
      }
    });
  }

  void _startRandom() {
    Navigator.of(context).pop(const RandomActivityMarkers());
  }

  void _startSelected() {
    if (_selectedIds.isEmpty) {
      return;
    }
    Navigator.of(context).pop(SelectedActivityMarkers(_selectedIds.toList()));
  }

  void _showMarkerHelp() {
    final texts = AppTexts.of(context).mealIngredient;
    showAppHelpSheet(
      context: context,
      title: texts.helpTitle,
      bodyParagraphs: texts.helpBodyParagraphs,
      bulletItems: texts.helpBulletItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).mealIngredient;
    final textTheme = Theme.of(context).textTheme;
    final maxCount = ActivityMarkerCatalog.maxSelectableMarkerCount;
    final mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.92),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: AppShadows.hero,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl +
                    mediaQuery.padding.bottom +
                    mediaQuery.viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  key: const ValueKey('activityMarkerPickerSheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.borderSoft,
                          borderRadius: AppRadius.pill,
                        ),
                        child: const SizedBox(width: 44, height: 5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                texts.title,
                                style: textTheme.titleLarge?.copyWith(
                                  color: AppColors.textStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                texts.subtitle,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  key: const ValueKey(
                                    'activityMarkerPickerHelpButton',
                                  ),
                                  onPressed: _showMarkerHelp,
                                  icon: const Icon(
                                    Icons.help_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(texts.helpLinkLabel),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.brown700,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.white.withValues(
                              alpha: 0.72,
                            ),
                            foregroundColor: AppColors.brown700,
                            fixedSize: const Size(44, 44),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      texts.selectedCount(_selectedIds.length, maxCount),
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final marker in _availableMarkers)
                          _MarkerChoiceChip(
                            marker: marker,
                            isSelected: _selectedIds.contains(marker.id),
                            isEnabled:
                                _selectedIds.contains(marker.id) ||
                                _selectedIds.length < maxCount,
                            onSelected: () => _toggleMarker(marker),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey(
                              'randomStartActivityMarkersButton',
                            ),
                            onPressed: _startRandom,
                            icon: const Icon(Icons.shuffle_rounded),
                            label: Text(texts.randomStartButton),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey(
                              'startSelectedActivityMarkersButton',
                            ),
                            onPressed: _selectedIds.isEmpty
                                ? null
                                : _startSelected,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(texts.selectedStartButton),
                          ),
                        ),
                      ],
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

class _MarkerChoiceChip extends StatelessWidget {
  const _MarkerChoiceChip({
    required this.marker,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelected,
  });

  final ActivityMarkerDefinition marker;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final label = marker.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );

    return ChoiceChip(
      key: ValueKey('activityMarkerChip_${marker.id}'),
      selected: isSelected,
      onSelected: isEnabled ? (_) => onSelected() : null,
      avatar: _MarkerChipAvatar(marker: marker),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: isSelected ? AppColors.textStrong : AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: AppColors.surfaceYellow,
      backgroundColor: AppColors.white.withValues(alpha: 0.82),
      disabledColor: AppColors.white.withValues(alpha: 0.44),
      side: BorderSide(
        color: isSelected ? AppColors.primarySoft : AppColors.borderSoft,
      ),
      showCheckmark: false,
    );
  }
}

class _MarkerChipAvatar extends StatelessWidget {
  const _MarkerChipAvatar({required this.marker});

  final ActivityMarkerDefinition marker;

  @override
  Widget build(BuildContext context) {
    final assetPath = marker.assetPath;
    if (assetPath == null) {
      return Text(marker.emoji);
    }

    return SizedBox(
      width: 22,
      height: 22,
      child: Image.asset(
        assetPath,
        key: ValueKey('activityMarkerChipImage_${marker.id}'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Text(marker.emoji));
        },
      ),
    );
  }
}
