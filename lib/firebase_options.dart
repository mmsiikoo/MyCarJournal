import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Конфігурація Firebase для проєкту mycarjournal-71dbe.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions не налаштовані для цієї платформи.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1G62lzCgP29Ze1S9k99sT3fj-YPpECMY',
    appId: '1:169355243416:web:e4d449142238f6cc41c5ed',
    messagingSenderId: '169355243416',
    projectId: 'mycarjournal-71dbe',
    authDomain: 'mycarjournal-71dbe.firebaseapp.com',
    storageBucket: 'mycarjournal-71dbe.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCF3Xf-0lww--w34fVljO3n8CbAs-zCYTM',
    appId: '1:169355243416:android:121131c2b9480e0c41c5ed',
    messagingSenderId: '169355243416',
    projectId: 'mycarjournal-71dbe',
    storageBucket: 'mycarjournal-71dbe.firebasestorage.app',
  );
}
