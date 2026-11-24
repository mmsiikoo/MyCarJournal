import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataRepository {
  UserDataRepository(this._db);

  final FirebaseFirestore _db;

  Future<void> deleteAllData(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final refs = <DocumentReference<Map<String, dynamic>>>[];

    for (final name in ['vehicles', 'fuelEntries', 'events']) {
      final docs = await userRef.collection(name).get();
      refs.addAll(docs.docs.map((doc) => doc.reference));
    }

    final events = await userRef.collection('events').get();
    for (final event in events.docs) {
      final photos = await event.reference.collection('photos').get();
      refs.addAll(photos.docs.map((doc) => doc.reference));
    }

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
