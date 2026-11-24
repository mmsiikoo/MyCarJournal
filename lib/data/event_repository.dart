import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_photo.dart';
import '../models/maintenance_event.dart';

class EventRepository {
  EventRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _events(String uid) =>
      _db.collection('users').doc(uid).collection('events');

  Stream<List<MaintenanceEvent>> watchEvents(String uid) {
    return _events(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaintenanceEvent.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<EventPhoto>> watchPhotos(String uid, String eventId) {
    return _events(uid)
        .doc(eventId)
        .collection('photos')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventPhoto.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> saveEvent({
    required String uid,
    required MaintenanceEvent event,
    required List<PickedPhoto> newPhotos,
    required List<String> removedPhotoIds,
    void Function(int uploaded, int total)? onProgress,
  }) async {
    final collection = _events(uid);
    final isNew = event.id.isEmpty;
    final ref = isNew ? collection.doc() : collection.doc(event.id);

    final initialPhotoCount = event.photoCount + newPhotos.length;

    final data = <String, dynamic>{
      ...event.toMap(),
      'photoCount': initialPhotoCount,
    };
    if (isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
    } else {
      await ref.update(data);
    }

    final photosRef = ref.collection('photos');
    for (final photoId in removedPhotoIds) {
      await photosRef.doc(photoId).delete();
    }

    var uploaded = 0;
    for (final photo in newPhotos) {
      await photosRef.add({
        'data': photo.data,
        'thumb': photo.thumb,
        'width': photo.width,
        'height': photo.height,
        'size': photo.size,
        'createdAt': FieldValue.serverTimestamp(),
      });
      uploaded++;
      onProgress?.call(uploaded, newPhotos.length);
    }

    final countSnapshot = await photosRef.count().get();
    final totalPhotos = countSnapshot.count ?? 0;

    final firstPhoto = await photosRef.orderBy('createdAt').limit(1).get();
    final coverThumb = firstPhoto.docs.isEmpty
        ? null
        : firstPhoto.docs.first.data()['thumb'] as String?;

    await ref.update({'photoCount': totalPhotos, 'coverThumb': coverThumb});

    return ref.id;
  }

  Future<void> deleteEvent(String uid, String eventId) async {
    final ref = _events(uid).doc(eventId);
    final photos = await ref.collection('photos').get();
    final batch = _db.batch();
    for (final photo in photos.docs) {
      batch.delete(photo.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }
}
