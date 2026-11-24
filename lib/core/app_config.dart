import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const appName = 'MyCarJournal';
  static const version = '1.0.0';
  static const productionUrl = 'https://mycarjournal-71dbe.web.app';

  static String get continueUrl {
    final origin = kIsWeb ? Uri.base.origin : productionUrl;
    if (origin.isEmpty || origin == 'null') return '$productionUrl/';
    return origin.endsWith('/') ? origin : '$origin/';
  }
}
