import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/fuel_entry.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/vehicle_selector.dart';

class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FuelEntry entry,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Видалити заправку?',
      message:
          '${formatDate(entry.date)} • ${formatLiters(entry.liters)} • ${formatMoney(entry.totalCost)}',
      confirmLabel: 'Видалити',
      destructive: true,
    );
    if (!confirmed) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await ref.read(fuelRepositoryProvider).delete(uid, entry.id);
      if (!context.mounted) return;
      showAppSnack(context, 'Заправку видалено');
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, 'Помилка видалення: $error', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(activeVehicleProvider);
    final entries = ref.watch(activeVehicleFuelEntriesProvider);
    final stats = ref.watch(fuelStatsProvider);
    final theme = Theme.of(context);

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Журнал заправок')),
        body: EmptyState(
          icon: Icons.local_gas_station_outlined,
          title: 'Спочатку додайте авто',
          message: 'Журнал заправок прив’язаний до автомобіля. Додайте його у гаражі.',
          actionLabel: 'Перейти в гараж',
          onAction: () => context.go('/garage'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал заправок'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: VehicleSelector(compact: true)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fuel/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Заправка'),
      ),
      body: SafeArea(
        child: entries.isEmpty
            ? EmptyState(
                icon: Icons.local_gas_station_outlined,
                title: 'Заправок ще немає',
                message:
                    'Додайте першу заправку. Для розрахунку витрати позначте повний бак — '
                    'розрахунок ведеться методом «від повного бака до повного».',
                actionLabel: 'Додати заправку',
                onAction: () => context.push('/fuel/new'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _SummaryCard(
                    consumption: stats.averageConsumption,
                    totalCost: stats.totalCost,
                    totalLiters: stats.totalLiters,
                    entriesCount: entries.length,
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
                              label: 'Остання витрата',
                              value: stats.lastConsumption == null
                                  ? '—'
                                  : formatConsumption(stats.lastConsumption!),
                              icon: Icons.local_fire_department_outlined,
                              accent: AppColors.secondary,
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ..._buildGroupedList(context, ref, entries, theme),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<FuelEntry> entries,
    ThemeData theme,
  ) {
    final widgets = <Widget>[];
    String? currentGroup;
    for (final entry in entries) {
      final group = formatMonthYear(entry.date);
      if (group != currentGroup) {
        currentGroup = group;
        final monthTotal = entries
            .where((candidate) => isSameMonth(candidate.date, entry.date))
            .fold<double>(0, (sum, candidate) => sum + candidate.totalCost);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(group, style: theme.textTheme.titleSmall)),
                Text(
                  formatMoney(monthTotal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(
        _FuelTile(entry: entry, onDelete: () => _delete(context, ref, entry)),
      );
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.consumption,
    required this.totalCost,
    required this.totalLiters,
    required this.entriesCount,
  });

  final double? consumption;
  final double totalCost;
  final double totalLiters;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3B4C), Color(0xFF17222D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Середня витрата',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                consumption == null ? '—' : formatDecimal(consumption!),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  ' л/100 км',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Витрачено',
                  value: formatMoney(totalCost, whole: true),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Пального',
                  value: formatLiters(totalLiters),
                ),
              ),
              Expanded(
                child: _Metric(label: 'Заправок', value: '$entriesCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _FuelTile extends StatelessWidget {
  const _FuelTile({required this.entry, required this.onDelete});

  final FuelEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/fuel/${entry.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  entry.isFullTank
                      ? Icons.local_gas_station_rounded
                      : Icons.local_gas_station_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          formatLiters(entry.liters),
                          style: theme.textTheme.titleSmall,
                        ),
                        if (entry.isFullTank) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'повний',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatDate(entry.date)} • ${formatOdometer(entry.odometer)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                      ),
                    ),
                    if (entry.station.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.station,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(entry.totalCost),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPricePerLiter(entry.pricePerLiter),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/fuel/${entry.id}/edit');
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Редагувати')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Видалити',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
