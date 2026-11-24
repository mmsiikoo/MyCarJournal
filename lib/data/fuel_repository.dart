import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fuel_entry.dart';

class FuelRepository {
  FuelRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _fuel(String uid) =>
      _db.collection('users').doc(uid).collection('fuelEntries');

  Stream<List<FuelEntry>> watchEntries(String uid) {
    return _fuel(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FuelEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> create(String uid, FuelEntry entry) async {
    final ref = _fuel(uid).doc();
    await ref.set({
      ...entry.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(String uid, FuelEntry entry) {
    return _fuel(uid).doc(entry.id).update(entry.toMap());
  }

  Future<void> delete(String uid, String entryId) {
    return _fuel(uid).doc(entryId).delete();
  }
}
