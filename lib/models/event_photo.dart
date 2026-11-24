import 'package:cloud_firestore/cloud_firestore.dart';

class EventPhoto {
  const EventPhoto({
    required this.id,
    required this.data,
    required this.thumb,
    required this.width,
    required this.height,
    required this.size,
    required this.createdAt,
  });

  final String id;
  final String data;
  final String thumb;
  final int width;
  final int height;
  final int size;
  final DateTime createdAt;

  factory EventPhoto.fromMap(String id, Map<String, dynamic> map) {
    return EventPhoto(
      id: id,
      data: (map['data'] as String?) ?? '',
      thumb: (map['thumb'] as String?) ?? '',
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      size: (map['size'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class PickedPhoto {
  const PickedPhoto({
    required this.data,
    required this.thumb,
    required this.width,
    required this.height,
    required this.size,
  });

  final String data;
  final String thumb;
  final int width;
  final int height;
  final int size;
}
