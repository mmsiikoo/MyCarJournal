String resolveDisplayName({String? displayName, String? email}) {
  final name = displayName?.trim() ?? '';
  if (name.isNotEmpty) return name;
  final mail = email?.trim() ?? '';
  if (mail.isNotEmpty) return mail.split('@').first;
  return 'Користувач';
}

String firstNameOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'друже';
  return trimmed.split(RegExp(r'\s+')).first;
}
