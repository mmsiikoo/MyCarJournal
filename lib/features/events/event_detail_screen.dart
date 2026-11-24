import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/event_photo.dart';
import '../../models/maintenance_event.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/base64_image.dart';
import '../../shared/widgets/confirm_dialog.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Видалити подію?',
      message: 'Подію та всі її фото буде видалено назавжди.',
      confirmLabel: 'Видалити',
      destructive: true,
    );
    if (!confirmed) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(uid, eventId);
      if (!context.mounted) return;
      showAppSnack(context, 'Подію видалено');
      context.pop();
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, 'Помилка видалення: $error', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.value ?? const <MaintenanceEvent>[];
    MaintenanceEvent? event;
    for (final candidate in events) {
      if (candidate.id == eventId) {
        event = candidate;
        break;
      }
    }

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Подія')),
        body: eventsAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Подію не знайдено')),
      );
    }

    final photosAsync = ref.watch(eventPhotosProvider(eventId));
    final photos = photosAsync.value ?? const <EventPhoto>[];
    final vehicle = ref.watch(activeVehicleProvider);
    final theme = Theme.of(context);
    final category = event.category;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подія'),
        actions: [
          IconButton(
            tooltip: 'Редагувати',
            onPressed: () => context.push('/events/$eventId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Видалити',
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          category.color.withValues(alpha: 0.24),
                          const Color(0xFF17222D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(category.icon, color: category.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.label,
                                    style: TextStyle(
                                      color: category.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event.title,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 18,
                          runSpacing: 10,
                          children: [
                            _InfoPill(
                              icon: Icons.event_outlined,
                              text: formatDate(event.date),
                            ),
                            if (event.odometer != null)
                              _InfoPill(
                                icon: Icons.speed_outlined,
                                text: formatOdometer(event.odometer!),
                              ),
                            if (event.cost != null)
                              _InfoPill(
                                icon: Icons.payments_outlined,
                                text: formatMoney(event.cost!),
                              ),
                            if (vehicle != null)
                              _InfoPill(
                                icon: Icons.directions_car_outlined,
                                text: vehicle.title,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (event.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Нотатки', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text(
                              event.notes,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (event.nextDueDate != null ||
                      event.nextDueOdometer != null) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Наступне ТО',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (event.nextDueDate != null)
                                        'до ${formatDate(event.nextDueDate!)}',
                                      if (event.nextDueOdometer != null)
                                        'на ${formatOdometer(event.nextDueOdometer!)}',
                                    ].join(' • '),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Фото (${photos.length})',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (photos.isNotEmpty)
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/events/$eventId/photos'),
                          icon: const Icon(
                            Icons.open_in_full_rounded,
                            size: 18,
                          ),
                          label: const Text('Відкрити'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (photosAsync.isLoading && photos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (photos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 36,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'До цієї події фото не додано',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 640 ? 4 : 3;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: photos.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return GestureDetector(
                              onTap: () => context.push(
                                '/events/$eventId/photos?index=$index',
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Base64Image(photo.thumb),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
