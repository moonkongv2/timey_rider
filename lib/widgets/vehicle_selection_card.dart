import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import '../models/vehicle.dart';

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
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final chipWidth = (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final vehicle in VehicleCatalog.all)
                      _VehicleChoiceButton(
                        width: chipWidth,
                        vehicle: vehicle,
                        isSelected: selectedVehicle.id == vehicle.id,
                        onTap: () => onVehicleSelected(vehicle.id),
                      ),
                  ],
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
    required this.width,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  final double width;
  final VehicleDefinition vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? colorScheme.primary
        : const Color(0xFFEAD8C7);
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer.withValues(alpha: 0.72)
        : colorScheme.surface;
    final borderRadius = BorderRadius.circular(24);

    return SizedBox(
      width: width,
      height: 104,
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
            side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: SizedBox(
                width: 78,
                height: 78,
                child: Image.asset(
                  vehicle.selectionImagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        vehicle.emoji,
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(fontSize: 52, height: 1),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
