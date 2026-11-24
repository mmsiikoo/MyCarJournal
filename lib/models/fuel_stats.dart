import 'fuel_entry.dart';

class FuelSegment {
  const FuelSegment({
    required this.startDate,
    required this.endDate,
    required this.startOdometer,
    required this.endOdometer,
    required this.liters,
    required this.cost,
    required this.consumption,
  });

  final DateTime startDate;
  final DateTime endDate;
  final double startOdometer;
  final double endOdometer;
  final double liters;
  final double cost;
  final double consumption;

  double get distance => endOdometer - startOdometer;
}

class FuelStats {
  const FuelStats({
    required this.segments,
    required this.totalLiters,
    required this.totalCost,
    required this.averageConsumption,
    required this.lastConsumption,
    required this.averagePrice,
    required this.costPerKm,
    required this.trackedDistance,
  });

  final List<FuelSegment> segments;
  final double totalLiters;
  final double totalCost;
  final double? averageConsumption;
  final double? lastConsumption;
  final double? averagePrice;
  final double? costPerKm;
  final double trackedDistance;

  bool get hasSegments => segments.isNotEmpty;

  static const empty = FuelStats(
    segments: [],
    totalLiters: 0,
    totalCost: 0,
    averageConsumption: null,
    lastConsumption: null,
    averagePrice: null,
    costPerKm: null,
    trackedDistance: 0,
  );

  factory FuelStats.fromEntries(Iterable<FuelEntry> input) {
    final entries = input.toList()
      ..sort((a, b) {
        final byOdometer = a.odometer.compareTo(b.odometer);
        if (byOdometer != 0) return byOdometer;
        return a.date.compareTo(b.date);
      });

    var totalLiters = 0.0;
    var totalCost = 0.0;
    for (final entry in entries) {
      totalLiters += entry.liters;
      totalCost += entry.totalCost;
    }

    final segments = <FuelSegment>[];
    FuelEntry? previousFull;

    for (final entry in entries) {
      if (!entry.isFullTank) continue;
      if (previousFull != null) {
        final distance = entry.odometer - previousFull.odometer;
        final segmentEntries = entries.where(
          (candidate) =>
              candidate.odometer > previousFull!.odometer &&
              candidate.odometer <= entry.odometer,
        );
        var liters = 0.0;
        var cost = 0.0;
        for (final candidate in segmentEntries) {
          liters += candidate.liters;
          cost += candidate.totalCost;
        }
        if (distance > 0 && liters > 0) {
          segments.add(
            FuelSegment(
              startDate: previousFull.date,
              endDate: entry.date,
              startOdometer: previousFull.odometer,
              endOdometer: entry.odometer,
              liters: liters,
              cost: cost,
              consumption: liters / distance * 100,
            ),
          );
        }
      }
      previousFull = entry;
    }

    var trackedDistance = 0.0;
    var trackedLiters = 0.0;
    var trackedCost = 0.0;
    for (final segment in segments) {
      trackedDistance += segment.distance;
      trackedLiters += segment.liters;
      trackedCost += segment.cost;
    }

    final averageConsumption = trackedDistance > 0
        ? trackedLiters / trackedDistance * 100
        : null;
    final averagePrice = totalLiters > 0 ? totalCost / totalLiters : null;
    final costPerKm = trackedDistance > 0
        ? trackedCost / trackedDistance
        : null;

    return FuelStats(
      segments: segments,
      totalLiters: totalLiters,
      totalCost: totalCost,
      averageConsumption: averageConsumption,
      lastConsumption: segments.isEmpty ? null : segments.last.consumption,
      averagePrice: averagePrice,
      costPerKm: costPerKm,
      trackedDistance: trackedDistance,
    );
  }
}
