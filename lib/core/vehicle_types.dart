import 'package:flutter/material.dart';

import 'app_colors.dart';

enum MaintenanceCategory {
  oil('Заміна мастила', Icons.water_drop_outlined, Color(0xFFE0A100)),
  brakes('Гальмівна система', Icons.disc_full_outlined, Color(0xFFFF6B6B)),
  tires('Шини та диски', Icons.tire_repair_outlined, Color(0xFF4FD1C5)),
  filters('Фільтри', Icons.air_outlined, Color(0xFF7C9BFF)),
  battery(
    'Акумулятор',
    Icons.battery_charging_full_outlined,
    Color(0xFF52D68A),
  ),
  inspection('Техогляд', Icons.verified_outlined, Color(0xFFB68CFF)),
  insurance('Страхування', Icons.shield_outlined, Color(0xFF8AB4F8)),
  repair('Ремонт', Icons.build_outlined, Color(0xFFFF9F68)),
  other('Інше', Icons.more_horiz, AppColors.textSecondary);

  const MaintenanceCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static MaintenanceCategory fromCode(String? code) {
    return MaintenanceCategory.values.firstWhere(
      (category) => category.name == code,
      orElse: () => MaintenanceCategory.other,
    );
  }
}

enum FuelType {
  petrol('Бензин', Icons.local_gas_station_outlined),
  diesel('Дизель', Icons.local_shipping_outlined),
  gas('Газ', Icons.propane_tank_outlined),
  hybrid('Гібрид', Icons.eco_outlined),
  electric('Електро', Icons.electric_bolt_outlined);

  const FuelType(this.label, this.icon);

  final String label;
  final IconData icon;

  static FuelType fromCode(String? code) {
    return FuelType.values.firstWhere(
      (type) => type.name == code,
      orElse: () => FuelType.petrol,
    );
  }
}
