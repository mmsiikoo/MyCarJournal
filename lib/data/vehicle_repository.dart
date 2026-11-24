import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vehicle.dart';

class VehicleRepository {
  VehicleRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _vehicles(String uid) =>
      _db.collection('users').doc(uid).collection('vehicles');

  CollectionReference<Map<String, dynamic>> _fuel(String uid) =>
      _db.collection('users').doc(uid).collection('fuelEntries');

  CollectionReference<Map<String, dynamic>> _events(String uid) =>
      _db.collection('users').doc(uid).collection('events');

  Stream<List<Vehicle>> watchVehicles(String uid) {
    return _vehicles(uid)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Vehicle.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> create(String uid, Vehicle vehicle) async {
    final ref = _vehicles(uid).doc();
    await ref.set({
      ...vehicle.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(String uid, Vehicle vehicle) {
    return _vehicles(uid).doc(vehicle.id).update(vehicle.toMap());
  }

  Future<void> deleteCascade(String uid, String vehicleId) async {
    final fuelDocs = await _fuel(uid)
        .where('vehicleId', isEqualTo: vehicleId)
        .get();
    final eventDocs = await _events(uid)
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    final refs = <DocumentReference<Map<String, dynamic>>>[
      ...fuelDocs.docs.map((doc) => doc.reference),
      ...eventDocs.docs.map((doc) => doc.reference),
    ];

    for (final event in eventDocs.docs) {
      final photos = await event.reference.collection('photos').get();
      refs.addAll(photos.docs.map((doc) => doc.reference));
    }

    refs.add(_vehicles(uid).doc(vehicleId));
    await _deleteInBatches(refs);
  }

  Future<void> _deleteInBatches(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    var batch = _db.batch();
    var counter = 0;
    for (final ref in refs) {
      batch.delete(ref);
      counter++;
      if (counter >= 400) {
        await batch.commit();
        batch = _db.batch();
        counter = 0;
      }
    }
    if (counter > 0) {
      await batch.commit();
    }
  }
}
