import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/vehicle_types.dart';
import '../../models/maintenance_event.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/base64_image.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/vehicle_selector.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  MaintenanceCategory? _category;

  Future<void> _delete(MaintenanceEvent event) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Видалити подію?',
      message:
          '«${event.title}» та ${event.photoCount} фото буде видалено назавжди.',
      confirmLabel: 'Видалити',
      destructive: true,
    );
    if (!confirmed) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(uid, event.id);
      if (!mounted) return;
      showAppSnack(context, 'Подію видалено');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, 'Помилка видалення: $error', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(activeVehicleProvider);
    final allEvents = ref.watch(activeVehicleEventsProvider);
    final events = _category == null
        ? allEvents
        : allEvents.where((event) => event.category == _category).toList();
    final theme = Theme.of(context);

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Журнал подій')),
        body: EmptyState(
          icon: Icons.build_outlined,
          title: 'Спочатку додайте авто',
          message: 'Журнал обслуговування ведеться для кожного автомобіля.',
          actionLabel: 'Перейти в гараж',
          onAction: () => context.go('/garage'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал подій'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: VehicleSelector(compact: true)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Подія'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Усі'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                  ),
                  for (final category in MaintenanceCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          category.icon,
                          size: 16,
                          color: _category == category
                              ? category.color
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        label: Text(category.label),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: allEvents.isEmpty
                  ? EmptyState(
                      icon: Icons.build_outlined,
                      title: 'Подій ще немає',
                      message:
                          'Фіксуйте заміну мастила, гальмівних колодок, шин та інші роботи. '
                          'До кожної події можна додати до 5 фото.',
                      actionLabel: 'Додати подію',
                      onAction: () => context.push('/events/new'),
                    )
                  : events.isEmpty
                  ? const EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'Немає подій у цій категорії',
                      message: 'Оберіть іншу категорію або додайте нову подію.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _EventCard(
                          event: event,
                          onDelete: () => _delete(event),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onDelete});

  final MaintenanceEvent event;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = event.category;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: event.coverThumb == null
                      ? Container(
                          color: category.color.withValues(alpha: 0.15),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 28,
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
                    Row(
                      children: [
                        Icon(category.icon, size: 14, color: category.color),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            category.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: category.color,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        formatDate(event.date),
                        if (event.odometer != null)
                          formatOdometer(event.odometer!),
                        if (event.photoCount > 0) '${event.photoCount} фото',
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (event.cost != null)
                    Text(
                      formatMoney(event.cost!),
                      style: theme.textTheme.titleSmall,
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/events/${event.id}/edit');
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
            ],
          ),
        ),
      ),
    );
  }
}
