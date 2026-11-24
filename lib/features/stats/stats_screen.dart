import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/vehicle_types.dart';
import '../../models/fuel_stats.dart';
import '../../models/fuel_entry.dart';
import '../../models/maintenance_event.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/vehicle_selector.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(activeVehicleProvider);
    final entries = ref.watch(activeVehicleFuelEntriesProvider);
    final events = ref.watch(activeVehicleEventsProvider);
    final stats = ref.watch(fuelStatsProvider);
    final theme = Theme.of(context);

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Статистика')),
        body: EmptyState(
          icon: Icons.insights_outlined,
          title: 'Немає даних для аналізу',
          message:
              'Додайте авто, заправки та події — і тут з’явиться статистика.',
          actionLabel: 'Перейти в гараж',
          onAction: () => context.go('/garage'),
        ),
      );
    }

    if (entries.isEmpty && events.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: VehicleSelector(compact: true)),
            ),
          ],
        ),
        body: EmptyState(
          icon: Icons.insights_outlined,
          title: 'Ще немає статистики',
          message:
              'Додайте хоча б дві заправки з повним баком, щоб побачити витрату пального, '
              'а також події з вартістю для аналізу витрат.',
          actionLabel: 'Додати заправку',
          onAction: () => context.push('/fuel/new'),
        ),
      );
    }

    final maintenanceCost = events.fold<double>(
      0,
      (sum, event) => sum + (event.cost ?? 0),
    );
    final monthly = _monthlyData(entries, events);
    final categoryTotals = _categoryTotals(events);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: VehicleSelector(compact: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(vehicle.title, style: theme.textTheme.titleLarge),
            Text(
              vehicle.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: width,
                      child: StatCard(
                        label: 'Середня витрата',
                        value: stats.averageConsumption == null
                            ? '—'
                            : formatConsumption(stats.averageConsumption!),
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        label: 'Ціна 1 км',
                        value: stats.costPerKm == null
                            ? '—'
                            : formatMoney(stats.costPerKm!),
                        icon: Icons.route_outlined,
                        accent: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        label: 'Витрати на пальне',
                        value: formatMoney(stats.totalCost, whole: true),
                        icon: Icons.local_gas_station_outlined,
                        accent: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        label: 'Витрати на ТО',
                        value: formatMoney(maintenanceCost, whole: true),
                        icon: Icons.build_outlined,
                        accent: AppColors.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _ChartCard(
              title: 'Динаміка витрати пального',
              subtitle:
                  'Останні ${math.min(stats.segments.length, 12)} сегментів '
                  '«повний бак → повний бак»',
              child: stats.segments.length < 2
                  ? const _ChartPlaceholder(
                      message:
                          'Потрібно щонайменше дві заправки з повним баком, '
                          'між якими є проміжні заправки.',
                    )
                  : _ConsumptionChart(segments: stats.segments),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Витрати за місяцями',
              subtitle: 'Пальне та обслуговування за останні 6 місяців',
              legend: const [
                _LegendDot(color: AppColors.primary, label: 'Пальне'),
                _LegendDot(color: AppColors.secondary, label: 'Обслуговування'),
              ],
              child: _MonthlyChart(months: monthly),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Структура витрат на ТО',
              subtitle: 'Розподіл за категоріями подій',
              child: categoryTotals.isEmpty
                  ? const _ChartPlaceholder(
                      message: 'Додайте вартість до подій обслуговування, щоб побачити розподіл.',
                    )
                  : _CategoryChart(totals: categoryTotals),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Підсумок',
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Всього заправок',
                    value: '${entries.length}',
                  ),
                  _SummaryRow(
                    label: 'Всього пального',
                    value: formatLiters(stats.totalLiters),
                  ),
                  _SummaryRow(
                    label: 'Пройдено в сегментах',
                    value: formatOdometer(stats.trackedDistance),
                  ),
                  _SummaryRow(
                    label: 'Середня ціна літра',
                    value: stats.averagePrice == null
                        ? '—'
                        : formatMoney(stats.averagePrice!),
                  ),
                  _SummaryRow(
                    label: 'Подій обслуговування',
                    value: '${events.length}',
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_MonthData> _monthlyData(
  List<FuelEntry> entries,
  List<MaintenanceEvent> events,
) {
  final now = DateTime.now();
  final months = List.generate(6, (index) {
    return DateTime(now.year, now.month - (5 - index));
  });
  return [
    for (final month in months)
      _MonthData(
        month: month,
        fuel: entries
            .where((entry) => isSameMonth(entry.date, month))
            .fold<double>(0, (sum, entry) => sum + entry.totalCost),
        maintenance: events
            .where((event) => isSameMonth(event.date, month))
            .fold<double>(0, (sum, event) => sum + (event.cost ?? 0)),
      ),
  ];
}

Map<MaintenanceCategory, double> _categoryTotals(
  List<MaintenanceEvent> events,
) {
  final totals = <MaintenanceCategory, double>{};
  for (final event in events) {
    final cost = event.cost ?? 0;
    if (cost <= 0) continue;
    totals.update(
      event.category,
      (value) => value + cost,
      ifAbsent: () => cost,
    );
  }
  return totals;
}

class _MonthData {
  const _MonthData({
    required this.month,
    required this.fuel,
    required this.maintenance,
  });

  final DateTime month;
  final double fuel;
  final double maintenance;

  double get total => fuel + maintenance;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.legend,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? legend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
            if (legend != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 16, runSpacing: 6, children: legend!),
            ],
            const SizedBox(height: 16),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 34,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  const _ConsumptionChart({required this.segments});

  final List<FuelSegment> segments;

  @override
  Widget build(BuildContext context) {
    final visible = segments.length > 12
        ? segments.sublist(segments.length - 12)
        : segments;
    final spots = [
      for (var i = 0; i < visible.length; i++)
        FlSpot(i.toDouble(), visible[i].consumption),
    ];
    final values = visible.map((segment) => segment.consumption).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = math.max((maxValue - minValue) * 0.3, 0.5);
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return LineChart(
      LineChartData(
        minY: math.max(0, minValue - padding),
        maxY: maxValue + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max((maxValue - minValue) / 3, 1),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Text(
                formatDecimal(value),
                style: TextStyle(color: labelColor, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: math.max((visible.length / 4).ceilToDouble(), 1),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= visible.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    formatMonthShort(visible[index].endDate),
                    style: TextStyle(color: labelColor, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months});

  final List<_MonthData> months;

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold<double>(
      0,
      (value, month) => math.max(value, month.total),
    );
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return BarChart(
      BarChartData(
        maxY: maxValue <= 0 ? 100 : maxValue * 1.2,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue <= 0 ? 20 : math.max(maxValue / 3, 1),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                formatWhole(value),
                style: TextStyle(color: labelColor, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    formatMonthShort(months[index].month),
                    style: TextStyle(color: labelColor, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = months[group.x];
              final isFuel = rodIndex == 0;
              return BarTooltipItem(
                '${formatMonthYear(month.month)}\n'
                '${isFuel ? 'Пальне' : 'ТО'}: ${formatMoney(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: months[i].fuel,
                  color: AppColors.primary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: months[i].maintenance,
                  color: AppColors.secondary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.totals});

  final Map<MaintenanceCategory, double> totals;

  @override
  Widget build(BuildContext context) {
    final total = totals.values.fold<double>(0, (sum, value) => sum + value);
    final theme = Theme.of(context);
    final entries = totals.entries.toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 38,
              sections: [
                for (final entry in entries)
                  PieChartSectionData(
                    value: entry.value,
                    color: entry.key.color,
                    radius: 42,
                    title: total == 0
                        ? ''
                        : '${(entry.value / total * 100).round()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: entry.key.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        formatMoney(entry.value, whole: true),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (!last) ...[
          const SizedBox(height: 10),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
