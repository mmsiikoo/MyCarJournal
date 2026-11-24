import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/vehicle_types.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.nickname,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.fuelType,
    required this.tankCapacity,
    required this.initialOdometer,
    required this.createdAt,
  });

  final String id;
  final String nickname;
  final String make;
  final String model;
  final int? year;
  final String plate;
  final FuelType fuelType;
  final double? tankCapacity;
  final double initialOdometer;
  final DateTime createdAt;

  String get title {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    final name = [
      make.trim(),
      model.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    return name.isEmpty ? 'Моє авто' : name;
  }

  String get description {
    final parts = <String>[
      if (make.trim().isNotEmpty || model.trim().isNotEmpty)
        [make.trim(), model.trim()].where((part) => part.isNotEmpty).join(' '),
      if (year != null) '$year',
      if (plate.trim().isNotEmpty) plate.trim(),
    ];
    return parts.isEmpty ? fuelType.label : parts.join(' • ');
  }

  String get fullName =>
      [make.trim(), model.trim()].where((part) => part.isNotEmpty).join(' ');

  Map<String, dynamic> toMap() => {
    'nickname': nickname.trim(),
    'make': make.trim(),
    'model': model.trim(),
    'year': year,
    'plate': plate.trim().toUpperCase(),
    'fuelType': fuelType.name,
    'tankCapacity': tankCapacity,
    'initialOdometer': initialOdometer,
  };

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      nickname: (map['nickname'] as String?) ?? '',
      make: (map['make'] as String?) ?? '',
      model: (map['model'] as String?) ?? '',
      year: (map['year'] as num?)?.toInt(),
      plate: (map['plate'] as String?) ?? '',
      fuelType: FuelType.fromCode(map['fuelType'] as String?),
      tankCapacity: (map['tankCapacity'] as num?)?.toDouble(),
      initialOdometer: (map['initialOdometer'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Vehicle copyWith({
    String? nickname,
    String? make,
    String? model,
    int? year,
    String? plate,
    FuelType? fuelType,
    double? tankCapacity,
    double? initialOdometer,
  }) {
    return Vehicle(
      id: id,
      nickname: nickname ?? this.nickname,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      fuelType: fuelType ?? this.fuelType,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      createdAt: createdAt,
    );
  }
}
