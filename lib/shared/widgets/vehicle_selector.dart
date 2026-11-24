import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../providers/app_providers.dart';

class VehicleSelector extends ConsumerWidget {
  const VehicleSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final active = ref.watch(activeVehicleProvider);
    final theme = Theme.of(context);

    if (vehicles.isEmpty) return const SizedBox.shrink();

    if (vehicles.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                active?.title ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: active?.id,
          isDense: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          items: [
            for (final vehicle in vehicles)
              DropdownMenuItem(
                value: vehicle.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vehicle.fuelType.icon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(vehicle.title),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(selectedVehicleIdProvider.notifier).select(value);
            }
          },
        ),
      ),
    );
  }
}
