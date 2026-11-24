abstract final class Validators {
  static String? required(String? value, [String label = 'Поле']) {
    if (value == null || value.trim().isEmpty) {
      return '$label є обов’язковим';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'Email');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!regex.hasMatch(email)) return 'Введіть коректний email';
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, 'Пароль');
    if (requiredError != null) return requiredError;
    if (value!.length < 6) return 'Пароль має містити щонайменше 6 символів';
    return null;
  }

  static String? positiveNumber(
    String? value, {
    String label = 'Значення',
    bool allowZero = false,
  }) {
    final requiredError = required(value, label);
    if (requiredError != null) return requiredError;
    final parsed = parseNumber(value);
    if (parsed == null) return 'Введіть число';
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return allowZero
          ? '$label не може бути від’ємним'
          : '$label має бути більше 0';
    }
    return null;
  }

  static String? optionalNonNegative(
    String? value, [
    String label = 'Значення',
  ]) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = parseNumber(value);
    if (parsed == null) return 'Введіть число';
    if (parsed < 0) return '$label не може бути від’ємним';
    return null;
  }

  static String? optionalYear(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final year = int.tryParse(value.trim());
    final current = DateTime.now().year;
    if (year == null || year < 1900 || year > current + 1) {
      return 'Рік має бути між 1900 та ${current + 1}';
    }
    return null;
  }

  static double? parseNumber(String? value) {
    if (value == null) return null;
    final normalized = value.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}
