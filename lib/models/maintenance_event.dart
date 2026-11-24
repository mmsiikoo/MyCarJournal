import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/vehicle_types.dart';

class MaintenanceEvent {
  const MaintenanceEvent({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.title,
    required this.date,
    required this.odometer,
    required this.cost,
    required this.notes,
    required this.photoCount,
    required this.coverThumb,
    required this.nextDueDate,
    required this.nextDueOdometer,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final MaintenanceCategory category;
  final String title;
  final DateTime date;
  final double? odometer;
  final double? cost;
  final String notes;
  final int photoCount;
  final String? coverThumb;
  final DateTime? nextDueDate;
  final double? nextDueOdometer;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'category': category.name,
    'title': title.trim(),
    'date': Timestamp.fromDate(date),
    'odometer': odometer,
    'cost': cost,
    'notes': notes.trim(),
    'photoCount': photoCount,
    'coverThumb': coverThumb,
    'nextDueDate': nextDueDate == null
        ? null
        : Timestamp.fromDate(nextDueDate!),
    'nextDueOdometer': nextDueOdometer,
  };

  factory MaintenanceEvent.fromMap(String id, Map<String, dynamic> map) {
    return MaintenanceEvent(
      id: id,
      vehicleId: (map['vehicleId'] as String?) ?? '',
      category: MaintenanceCategory.fromCode(map['category'] as String?),
      title: (map['title'] as String?) ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      odometer: (map['odometer'] as num?)?.toDouble(),
      cost: (map['cost'] as num?)?.toDouble(),
      notes: (map['notes'] as String?) ?? '',
      photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
      coverThumb: map['coverThumb'] as String?,
      nextDueDate: (map['nextDueDate'] as Timestamp?)?.toDate(),
      nextDueOdometer: (map['nextDueOdometer'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MaintenanceEvent copyWith({int? photoCount, String? coverThumb}) {
    return MaintenanceEvent(
      id: id,
      vehicleId: vehicleId,
      category: category,
      title: title,
      date: date,
      odometer: odometer,
      cost: cost,
      notes: notes,
      photoCount: photoCount ?? this.photoCount,
      coverThumb: coverThumb ?? this.coverThumb,
      nextDueDate: nextDueDate,
      nextDueOdometer: nextDueOdometer,
      createdAt: createdAt,
    );
  }
}
