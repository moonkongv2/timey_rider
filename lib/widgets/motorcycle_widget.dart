import 'package:flutter/material.dart';

import '../catalogs/vehicle_catalog.dart';
import 'vehicle_widget.dart';

class MotorcycleWidget extends StatelessWidget {
  const MotorcycleWidget({
    super.key,
    this.size = 180,
    this.angle = 0,
    this.isArrived = false,
  });

  final double size;
  final double angle;
  final bool isArrived;

  @override
  Widget build(BuildContext context) {
    return VehicleWidget(
      vehicle: VehicleCatalog.motorcycle,
      size: size,
      angle: angle,
      isArrived: isArrived,
    );
  }
}
