import 'package:flutter_test/flutter_test.dart';
import 'package:my_car_journal/models/fuel_stats.dart';
import 'package:my_car_journal/models/fuel_entry.dart';

FuelEntry _entry({
  required double odometer,
  required double liters,
  required bool full,
  required DateTime date,
  double price = 50,
}) {
  return FuelEntry(
    id: '$odometer-$date',
    vehicleId: 'v1',
    date: date,
    odometer: odometer,
    liters: liters,
    pricePerLiter: price,
    isFullTank: full,
    station: '',
    notes: '',
    createdAt: date,
  );
}

void main() {
  group('FuelStats', () {
    test('рахує витрату методом повний бак → повний бак', () {
      final entries = [
        _entry(
          odometer: 1000,
          liters: 40,
          full: true,
          date: DateTime(2026, 1, 1),
        ),
        _entry(
          odometer: 1300,
          liters: 30,
          full: true,
          date: DateTime(2026, 1, 20),
        ),
        _entry(
          odometer: 1500,
          liters: 10,
          full: false,
          date: DateTime(2026, 2, 5),
        ),
        _entry(
          odometer: 1800,
          liters: 25,
          full: true,
          date: DateTime(2026, 2, 20),
        ),
      ];

      final stats = FuelStats.fromEntries(entries);

      expect(stats.segments.length, 2);
      expect(stats.segments[0].distance, 300);
      expect(stats.segments[0].liters, 30);
      expect(stats.segments[0].consumption, closeTo(10, 0.001));
      expect(stats.segments[1].distance, 500);
      expect(stats.segments[1].liters, 35);
      expect(stats.segments[1].consumption, closeTo(7, 0.001));
      expect(stats.averageConsumption, closeTo(8.125, 0.001));
      expect(stats.lastConsumption, closeTo(7, 0.001));
      expect(stats.trackedDistance, 800);
      expect(stats.totalLiters, 105);
      expect(stats.totalCost, closeTo(5250, 0.001));
      expect(stats.averagePrice, closeTo(50, 0.001));
      expect(stats.costPerKm, closeTo(3250 / 800, 0.001));
    });

    test('ігнорує часткові заправки до першого повного бака', () {
      final entries = [
        _entry(
          odometer: 500,
          liters: 10,
          full: false,
          date: DateTime(2026, 1, 1),
        ),
        _entry(
          odometer: 1000,
          liters: 40,
          full: true,
          date: DateTime(2026, 1, 10),
        ),
        _entry(
          odometer: 1400,
          liters: 32,
          full: true,
          date: DateTime(2026, 2, 10),
        ),
      ];

      final stats = FuelStats.fromEntries(entries);

      expect(stats.segments.length, 1);
      expect(stats.segments.single.distance, 400);
      expect(stats.segments.single.consumption, closeTo(8, 0.001));
    });

    test('сортує записи за пробігом незалежно від порядку', () {
      final entries = [
        _entry(
          odometer: 1800,
          liters: 25,
          full: true,
          date: DateTime(2026, 2, 20),
        ),
        _entry(
          odometer: 1000,
          liters: 40,
          full: true,
          date: DateTime(2026, 1, 1),
        ),
        _entry(
          odometer: 1300,
          liters: 30,
          full: true,
          date: DateTime(2026, 1, 20),
        ),
      ];

      final stats = FuelStats.fromEntries(entries);

      expect(stats.segments.length, 2);
      expect(stats.segments.first.startOdometer, 1000);
      expect(stats.segments.last.endOdometer, 1800);
    });

    test('без повних баків не рахує витрату', () {
      final entries = [
        _entry(
          odometer: 1000,
          liters: 20,
          full: false,
          date: DateTime(2026, 1, 1),
        ),
        _entry(
          odometer: 1200,
          liters: 15,
          full: false,
          date: DateTime(2026, 1, 20),
        ),
      ];

      final stats = FuelStats.fromEntries(entries);

      expect(stats.segments, isEmpty);
      expect(stats.averageConsumption, isNull);
      expect(stats.lastConsumption, isNull);
      expect(stats.costPerKm, isNull);
      expect(stats.totalLiters, 35);
    });

    test('порожній список дає порожню статистику', () {
      final stats = FuelStats.fromEntries(const []);

      expect(stats, isA<FuelStats>());
      expect(stats.segments, isEmpty);
      expect(stats.totalCost, 0);
      expect(stats.averageConsumption, isNull);
    });
  });
}
