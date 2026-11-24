import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/user_display.dart';
import '../../core/vehicle_types.dart';
import '../../models/maintenance_event.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/base64_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/vehicle_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.value ?? const [];
    final vehicle = ref.watch(activeVehicleProvider);
    final user = ref.watch(currentUserProvider);
    final entries = ref.watch(activeVehicleFuelEntriesProvider);
    final events = ref.watch(activeVehicleEventsProvider);
    final stats = ref.watch(fuelStatsProvider);
    final odometer = ref.watch(latestOdometerProvider);
    final theme = Theme.of(context);
    final displayName = resolveDisplayName(
      displayName: user?.displayName,
      email: user?.email,
    );
    final firstName = firstNameOf(displayName);

    final now = DateTime.now();
    final monthFuel = entries
        .where((entry) => isSameMonth(entry.date, now))
        .fold<double>(0, (sum, entry) => sum + entry.totalCost);
    final monthEvents = events
        .where((event) => isSameMonth(event.date, now))
        .fold<double>(0, (sum, event) => sum + (event.cost ?? 0));
    final monthTotal = monthFuel + monthEvents;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 30),
            const SizedBox(width: 10),
            const Text('MyCarJournal'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Профіль',
            onPressed: () => context.push('/profile'),
            icon: UserAvatar(name: displayName, email: user?.email, size: 36),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: vehiclesAsync.isLoading && vehicles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : vehicle == null
            ? EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'Вітаємо, $firstName!',
                message:
                    'Додайте своє авто, щоб почати вести журнал заправок, '
                    'витрат і обслуговування.',
                actionLabel: 'Додати авто',
                onAction: () => context.push('/garage/new'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Вітаю, $firstName',
                              style: theme.textTheme.headlineSmall,
                            ),
                            Text(
                              'Ось що відбувається з вашим авто',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VehicleSelector(compact: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _VehicleCard(
                    title: vehicle.title,
                    description: vehicle.description,
                    odometer: odometer,
                    fuelType: vehicle.fuelType,
                    plate: vehicle.plate,
                    onTap: () => context.push('/garage/${vehicle.id}/edit'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/fuel/new'),
                          icon: const Icon(Icons.local_gas_station_rounded),
                          label: const Text('Заправка'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/events/new'),
                          icon: const Icon(Icons.build_outlined),
                          label: const Text('Подія'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                                  : formatConsumption(
                                      stats.averageConsumption!,
                                    ),
                              icon: Icons.local_fire_department_outlined,
                              accent: AppColors.secondary,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: StatCard(
                              label:
                                  'Витрати за ${formatMonthShort(now).toLowerCase()}',
                              value: formatMoney(monthTotal, whole: true),
                              icon: Icons.account_balance_wallet_outlined,
                              accent: AppColors.success,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: StatCard(
                              label: 'Пробіг',
                              value: formatOdometer(odometer),
                              icon: Icons.speed_outlined,
                              accent: AppColors.primary,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: StatCard(
                              label: 'Заправок',
                              value: '${entries.length}',
                              icon: Icons.receipt_long_outlined,
                              accent: const Color(0xFFB68CFF),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (entries.length < 2) ...[
                    const SizedBox(height: 14),
                    _HintCard(
                      icon: Icons.tips_and_updates_outlined,
                      title: 'Як порахувати витрату?',
                      text:
                          'Додайте щонайменше дві заправки з позначкою «повний бак». '
                          'Застосунок порахує витрату між ними автоматично.',
                      actionLabel: 'Додати заправку',
                      onAction: () => context.push('/fuel/new'),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Нагадування про ТО',
                    actionLabel: events.isEmpty ? null : 'Усі події',
                    onAction: events.isEmpty
                        ? null
                        : () => context.go('/events'),
                  ),
                  const SizedBox(height: 8),
                  _UpcomingList(events: events, odometer: odometer),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Останні події',
                    actionLabel: events.isEmpty ? null : 'Усі',
                    onAction: events.isEmpty
                        ? null
                        : () => context.go('/events'),
                  ),
                  const SizedBox(height: 8),
                  if (events.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.build_outlined,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Тут з’являться заміни мастила, гальмівних колодок та інші роботи.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...events
                        .take(3)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecentEventTile(event: event),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.title,
    required this.description,
    required this.odometer,
    required this.fuelType,
    required this.plate,
    required this.onTap,
  });

  final String title;
  final String description;
  final double odometer;
  final FuelType fuelType;
  final String plate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF32475C), Color(0xFF17222D)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.directions_car_rounded,
                  size: 170,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            fuelType.icon,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plate.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              plate.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'ПОТОЧНИЙ ПРОБІГ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatWhole(odometer),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.05,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4, left: 6),
                          child: Text(
                            'км',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          fuelType.label,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.events, required this.odometer});

  final List<MaintenanceEvent> events;
  final double odometer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final upcoming = <MaintenanceEvent>[];

    for (final event in events) {
      var due = false;
      if (event.nextDueDate != null) {
        final days = event.nextDueDate!.difference(now).inDays;
        if (days <= 30) due = true;
      }
      if (event.nextDueOdometer != null) {
        final km = event.nextDueOdometer! - odometer;
        if (km <= 1000) due = true;
      }
      if (due) upcoming.add(event);
    }

    upcoming.sort((a, b) {
      final aDate = a.nextDueDate?.millisecondsSinceEpoch ?? 1 << 62;
      final bDate = b.nextDueDate?.millisecondsSinceEpoch ?? 1 << 62;
      return aDate.compareTo(bDate);
    });

    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Найближчим часом планових робіт немає. '
                'Додайте нагадування під час створення події.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final event in upcoming.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: event.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        event.category.icon,
                        color: event.category.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 3),
                          Text(
                            _dueLabel(event, odometer),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/events/${event.id}'),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _dueLabel(MaintenanceEvent event, double odometer) {
    final parts = <String>[];
    if (event.nextDueDate != null) {
      final days = event.nextDueDate!.difference(DateTime.now()).inDays;
      if (days < 0) {
        parts.add('прострочено на ${days.abs()} дн.');
      } else if (days == 0) {
        parts.add('сьогодні');
      } else {
        parts.add('через $days дн.');
      }
    }
    if (event.nextDueOdometer != null) {
      final km = event.nextDueOdometer! - odometer;
      if (km <= 0) {
        parts.add('пора замінити');
      } else {
        parts.add('через ${formatWhole(km)} км');
      }
    }
    return parts.join(' • ');
  }
}

class _RecentEventTile extends StatelessWidget {
  const _RecentEventTile({required this.event});

  final MaintenanceEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = event.category;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: event.coverThumb == null
                      ? Container(
                          color: category.color.withValues(alpha: 0.15),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 24,
                          ),
                        )
                      : Base64Image(event.coverThumb!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatDate(event.date)} • ${category.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (event.cost != null)
                Text(
                  formatMoney(event.cost!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
