import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';

class VehicleSelectionCard extends StatelessWidget {
  const VehicleSelectionCard({
    super.key,
    required this.title,
    required this.selectedVehicleId,
    required this.onVehicleSelected,
  });

  final String title;
  final String selectedVehicleId;
  final ValueChanged<String> onVehicleSelected;

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = VehicleCatalog.findById(selectedVehicleId);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final vehicle in VehicleCatalog.all)
                  ChoiceChip(
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vehicle.emoji,
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(fontSize: 28, height: 1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.labelForLanguage(
                            Localizations.localeOf(context).languageCode,
                          ),
                        ),
                      ],
                    ),
                    labelStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: selectedVehicle.id == vehicle.id
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFEAD8C7),
                    ),
                    selected: selectedVehicle.id == vehicle.id,
                    onSelected: (selected) {
                      if (!selected) {
                        return;
                      }
                      onVehicleSelected(vehicle.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
