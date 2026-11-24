import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Некоректний email.';
      case 'user-disabled':
        return 'Цей обліковий запис заблоковано.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Невірний email або пароль.';
      case 'email-already-in-use':
        return 'Користувач з таким email вже існує.';
      case 'weak-password':
        return 'Пароль занадто простий (мінімум 6 символів).';
      case 'too-many-requests':
        return 'Забагато спроб. Спробуйте пізніше.';
      case 'requires-recent-login':
        return 'Для цієї дії потрібно повторно увійти в акаунт.';
      case 'network-request-failed':
        return 'Немає з’єднання з мережею. Перевірте інтернет.';
      case 'operation-not-allowed':
        return 'Цей спосіб входу тимчасово недоступний.';
      case 'unauthorized-domain':
        return 'Цей домен не дозволений для входу. Зверніться до підтримки.';
      case 'unauthorized-continue-uri':
        return 'Не вдалося надіслати лист. Спробуйте пізніше.';
      case 'invalid-action-code':
      case 'expired-action-code':
        return 'Посилання недійсне або прострочене.';
      case 'user-token-expired':
        return 'Сесія завершилася. Увійдіть повторно.';
      case 'missing-password':
        return 'Введіть пароль.';
      default:
        return 'Не вдалося виконати дію. Спробуйте ще раз.';
    }
  }
  return genericErrorMessage(error);
}

String genericErrorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Немає доступу до даних. Спробуйте увійти повторно.';
      case 'unavailable':
        return 'Сервіс тимчасово недоступний. Перевірте інтернет.';
      case 'not-found':
        return 'Дані не знайдено.';
      case 'resource-exhausted':
        return 'Перевищено ліміт запитів. Спробуйте пізніше.';
      case 'deadline-exceeded':
        return 'Операція триває занадто довго. Спробуйте ще раз.';
      default:
        return 'Сталася помилка. Спробуйте ще раз.';
    }
  }
  return 'Сталася помилка. Спробуйте ще раз.';
}
