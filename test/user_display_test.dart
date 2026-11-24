import 'package:flutter_test/flutter_test.dart';
import 'package:my_car_journal/core/formatters.dart';
import 'package:my_car_journal/core/user_display.dart';

void main() {
  group('resolveDisplayName', () {
    test('uses a non-empty display name', () {
      expect(
        resolveDisplayName(displayName: '  Тарас Шевченко ', email: 't@x.com'),
        'Тарас Шевченко',
      );
    });

    test('falls back to the email prefix', () {
      expect(
        resolveDisplayName(displayName: '   ', email: 'taras@example.com'),
        'taras',
      );
    });

    test('falls back to a generic name', () {
      expect(resolveDisplayName(), 'Користувач');
    });
  });

  group('firstNameOf', () {
    test('returns the first word', () {
      expect(firstNameOf('Тарас Шевченко'), 'Тарас');
    });

    test('returns a friendly fallback for an empty name', () {
      expect(firstNameOf('   '), 'друже');
    });
  });

  group('initialsOf', () {
    test('uses the first and last word', () {
      expect(initialsOf('Тарас Григорович Шевченко'), 'ТШ');
    });

    test('uses the first two letters for a single word', () {
      expect(initialsOf('Тарас'), 'ТА');
    });

    test('returns a fallback for an empty name', () {
      expect(initialsOf('   '), 'MJ');
    });
  });
}
