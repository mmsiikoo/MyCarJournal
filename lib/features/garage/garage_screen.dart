import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/vehicle.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Видалити авто?',
      message:
          '«${vehicle.title}», усі його заправки, події та фото буде видалено назавжди.',
      confirmLabel: 'Видалити',
      destructive: true,
    );
    if (!confirmed) return;

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await ref.read(vehicleRepositoryProvider).deleteCascade(uid, vehicle.id);
      final selected = ref.read(selectedVehicleIdProvider);
      if (selected == vehicle.id) {
        ref.read(selectedVehicleIdProvider.notifier).select(null);
      }
      if (!context.mounted) return;
      showAppSnack(context, 'Авто видалено');
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, 'Не вдалося видалити авто: $error', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.value ?? const <Vehicle>[];
    final active = ref.watch(activeVehicleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Гараж'),
        actions: [
          IconButton(
            tooltip: 'Додати авто',
            onPressed: () => context.push('/garage/new'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/garage/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Додати авто'),
      ),
      body: SafeArea(
        child: vehiclesAsync.isLoading && vehicles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : vehicles.isEmpty
            ? EmptyState(
                icon: Icons.garage_outlined,
                title: 'Гараж порожній',
                message: 'Додайте своє перше авто, щоб вести облік пального та обслуговування.',
                actionLabel: 'Додати авто',
                onAction: () => context.push('/garage/new'),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: vehicles.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Автомобілів у гаражі: ${vehicles.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    );
                  }
                  final vehicle = vehicles[index - 1];
                  final isActive = active?.id == vehicle.id;
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push('/garage/${vehicle.id}/edit'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.13,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    vehicle.fuelType.icon,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              vehicle.title,
                                              style:
                                                  theme.textTheme.titleMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Активне',
                                                style: TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vehicle.description,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Пробіг: ${formatOdometer(vehicle.initialOdometer)} '
                                        '• ${vehicle.fuelType.label}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      context.push(
                                        '/garage/${vehicle.id}/edit',
                                      );
                                    } else if (value == 'delete') {
                                      await _delete(context, ref, vehicle);
                                    } else if (value == 'active') {
                                      ref
                                          .read(
                                            selectedVehicleIdProvider.notifier,
                                          )
                                          .select(vehicle.id);
                                      showAppSnack(
                                        context,
                                        'Активне авто: ${vehicle.title}',
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isActive)
                                      const PopupMenuItem(
                                        value: 'active',
                                        child: Text('Зробити активним'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Редагувати'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Видалити',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isActive) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(selectedVehicleIdProvider.notifier)
                                      .select(vehicle.id);
                                  showAppSnack(
                                    context,
                                    'Активне авто: ${vehicle.title}',
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Зробити активним'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
