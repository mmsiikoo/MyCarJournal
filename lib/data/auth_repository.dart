import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_config.dart';

class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      try {
        await user.updateDisplayName(name.trim());
        await user.reload();
      } catch (_) {}
    }
    return credential;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw _userNotFound();
    if (user.emailVerified) return;
    await _sendVerificationEmail(user);
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw _userNotFound();
    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  Future<void> sendPasswordReset(String email) async {
    await _setEmailLanguage();
    final normalized = email.trim();
    try {
      await _auth.sendPasswordResetEmail(
        email: normalized,
        actionCodeSettings: _actionCodeSettings(),
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'unauthorized-continue-uri') rethrow;
      await _auth.sendPasswordResetEmail(email: normalized);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw _userNotFound();
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw _userNotFound();
    await user.delete();
  }

  Future<void> _sendVerificationEmail(User user) async {
    await _setEmailLanguage();
    try {
      await user.sendEmailVerification(_actionCodeSettings());
    } on FirebaseAuthException catch (error) {
      if (error.code != 'unauthorized-continue-uri') rethrow;
      await user.sendEmailVerification();
    }
  }

  Future<void> _setEmailLanguage() async {
    try {
      await _auth.setLanguageCode('uk');
    } catch (_) {
      return;
    }
  }

  ActionCodeSettings _actionCodeSettings() {
    return ActionCodeSettings(url: AppConfig.continueUrl);
  }

  FirebaseAuthException _userNotFound() {
    return FirebaseAuthException(
      code: 'user-not-found',
      message: 'Користувача не знайдено.',
    );
  }
}
