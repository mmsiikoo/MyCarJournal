import 'package:cloud_firestore/cloud_firestore.dart';

class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.pricePerLiter,
    required this.isFullTank,
    required this.station,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final double odometer;
  final double liters;
  final double pricePerLiter;
  final bool isFullTank;
  final String station;
  final String notes;
  final DateTime createdAt;

  double get totalCost => liters * pricePerLiter;

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'date': Timestamp.fromDate(date),
    'odometer': odometer,
    'liters': liters,
    'pricePerLiter': pricePerLiter,
    'totalCost': totalCost,
    'isFullTank': isFullTank,
    'station': station.trim(),
    'notes': notes.trim(),
  };

  factory FuelEntry.fromMap(String id, Map<String, dynamic> map) {
    return FuelEntry(
      id: id,
      vehicleId: (map['vehicleId'] as String?) ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      odometer: (map['odometer'] as num?)?.toDouble() ?? 0,
      liters: (map['liters'] as num?)?.toDouble() ?? 0,
      pricePerLiter: (map['pricePerLiter'] as num?)?.toDouble() ?? 0,
      isFullTank: (map['isFullTank'] as bool?) ?? false,
      station: (map['station'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
