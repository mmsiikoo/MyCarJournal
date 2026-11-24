import 'package:flutter/material.dart';

import '../../core/formatters.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.email, this.size = 48});

  final String name;
  final String? email;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final color = _colorFor(label);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.22)!],
        ),
      ),
      child: Text(
        initialsOf(label),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  String get _label {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) return trimmedName;
    final mail = email?.trim() ?? '';
    if (mail.isNotEmpty) return mail.split('@').first;
    return '';
  }

  Color _colorFor(String value) {
    final source = value.isEmpty ? 'MyCarJournal' : value.toLowerCase();
    var hash = 0;
    for (final code in source.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.55, 0.42).toColor();
  }
}
