import 'package:flutter/material.dart';

import '../catalogs/meal_ingredient_catalog.dart';
import '../l10n/app_texts.dart';
import '../models/meal_ingredient.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

sealed class MealIngredientPickerResult {
  const MealIngredientPickerResult();
}

class RandomMealIngredients extends MealIngredientPickerResult {
  const RandomMealIngredients();
}

class SelectedMealIngredients extends MealIngredientPickerResult {
  SelectedMealIngredients(List<String> ingredientIds)
    : ingredientIds = List.unmodifiable(ingredientIds);

  final List<String> ingredientIds;
}

class MealIngredientPickerSheet extends StatefulWidget {
  const MealIngredientPickerSheet({
    super.key,
    this.initialSelectedIds = const [],
  });

  final List<String> initialSelectedIds;

  @override
  State<MealIngredientPickerSheet> createState() =>
      _MealIngredientPickerSheetState();
}

class _MealIngredientPickerSheetState extends State<MealIngredientPickerSheet> {
  late final Set<String> _selectedIds = _validInitialSelectedIds();

  Set<String> _validInitialSelectedIds() {
    final selectedIds = <String>{};
    for (final id in widget.initialSelectedIds) {
      if (selectedIds.length >=
          MealIngredientCatalog.maxSelectableIngredientCount) {
        break;
      }
      if (MealIngredientCatalog.findById(id) != null) {
        selectedIds.add(id);
      }
    }
    return selectedIds;
  }

  void _toggleIngredient(MealIngredientDefinition ingredient) {
    setState(() {
      if (_selectedIds.contains(ingredient.id)) {
        _selectedIds.remove(ingredient.id);
        return;
      }
      if (_selectedIds.length <
          MealIngredientCatalog.maxSelectableIngredientCount) {
        _selectedIds.add(ingredient.id);
      }
    });
  }

  void _startRandom() {
    Navigator.of(context).pop(const RandomMealIngredients());
  }

  void _startSelected() {
    if (_selectedIds.isEmpty) {
      return;
    }
    Navigator.of(context).pop(SelectedMealIngredients(_selectedIds.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context).mealIngredient;
    final textTheme = Theme.of(context).textTheme;
    final maxCount = MealIngredientCatalog.maxSelectableIngredientCount;
    final mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
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
                key: const ValueKey('mealIngredientPickerSheet'),
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
                      for (final ingredient in MealIngredientCatalog.all)
                        _IngredientChoiceChip(
                          ingredient: ingredient,
                          isSelected: _selectedIds.contains(ingredient.id),
                          isEnabled:
                              _selectedIds.contains(ingredient.id) ||
                              _selectedIds.length < maxCount,
                          onSelected: () => _toggleIngredient(ingredient),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey(
                            'randomStartMealIngredientsButton',
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
                            'startSelectedMealIngredientsButton',
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
    );
  }
}

class _IngredientChoiceChip extends StatelessWidget {
  const _IngredientChoiceChip({
    required this.ingredient,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelected,
  });

  final MealIngredientDefinition ingredient;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final label = ingredient.labelForLanguage(
      Localizations.localeOf(context).languageCode,
    );

    return ChoiceChip(
      key: ValueKey('mealIngredientChip_${ingredient.id}'),
      selected: isSelected,
      onSelected: isEnabled ? (_) => onSelected() : null,
      avatar: _IngredientChipAvatar(ingredient: ingredient),
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

class _IngredientChipAvatar extends StatelessWidget {
  const _IngredientChipAvatar({required this.ingredient});

  final MealIngredientDefinition ingredient;

  @override
  Widget build(BuildContext context) {
    final assetPath = ingredient.assetPath;
    if (assetPath == null) {
      return Text(ingredient.emoji);
    }

    return SizedBox(
      width: 22,
      height: 22,
      child: Image.asset(
        assetPath,
        key: ValueKey('mealIngredientChipImage_${ingredient.id}'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Text(ingredient.emoji));
        },
      ),
    );
  }
}
