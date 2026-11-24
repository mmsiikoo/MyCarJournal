import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(this._auth) {
    _subscription = _auth.authStateChanges().listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;
  User? _user;
  bool _initialized = false;

  User? get user => _user;
  bool get initialized => _initialized;

  Future<void> refreshUser() async {
    final current = _auth.currentUser;
    if (current == null) return;
    await current.reload();
    _user = _auth.currentUser;
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  final notifier = AuthRouterNotifier(ref.watch(firebaseAuthProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});
