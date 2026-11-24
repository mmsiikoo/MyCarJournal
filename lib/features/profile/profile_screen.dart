import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../../core/error_messages.dart';
import '../../core/formatters.dart';
import '../../core/user_display.dart';
import '../../core/validators.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/vehicle_selector.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Вийти з акаунта?',
      message: 'Дані залишаться в акаунті — ви зможете увійти знову.',
      confirmLabel: 'Вийти',
    );
    if (!confirmed) return;
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, authErrorMessage(error), error: true);
    }
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ваше ім’я'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            validator: (value) => Validators.required(value, 'Ім’я'),
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            decoration: const InputDecoration(
              labelText: 'Ім’я',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      if (!context.mounted) return;
      showAppSnack(context, 'Ім’я оновлено');
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, authErrorMessage(error), error: true);
    }
  }

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    final email = ref.read(currentUserProvider)?.email;
    if (email == null) return;
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!context.mounted) return;
      showAppSnack(context, 'Лист для зміни пароля надіслано на $email');
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, authErrorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final active = ref.watch(activeVehicleProvider);
    final theme = Theme.of(context);
    final name = resolveDisplayName(
      displayName: user?.displayName,
      email: user?.email,
    );
    final created = user?.metadata.creationTime;

    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          UserAvatar(name: name, email: user?.email, size: 72),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Редагувати ім’я',
                                      onPressed: () =>
                                          _editName(context, ref, name),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  user?.email ?? '—',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                if (created != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'З нами з ${formatDate(created)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const _StatusChip(
                                  icon: Icons.verified_outlined,
                                  label: 'Email підтверджено',
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Налаштування', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Тема оформлення'),
                          subtitle: const Text(
                            'Темна, світла або як у системі',
                          ),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<ThemeMode>(
                              value: themeMode,
                              borderRadius: BorderRadius.circular(16),
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Темна'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Світла'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('Системна'),
                                ),
                              ],
                              onChanged: (mode) {
                                if (mode != null) {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setMode(mode);
                                }
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car_outlined),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Активне авто',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      active?.description ??
                                          'Ще не додано жодного авто',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const VehicleSelector(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Безпека', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.verified_user_outlined),
                          title: const Text('Підтвердження email'),
                          subtitle: Text(user?.email ?? '—'),
                          trailing: const _StatusChip(
                            icon: Icons.check_rounded,
                            label: 'Активно',
                            color: AppColors.success,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.password_rounded),
                          title: const Text('Змінити пароль'),
                          subtitle: const Text(
                            'Надішлемо посилання на вашу пошту',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _sendPasswordReset(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Про застосунок', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const AppLogo(size: 40),
                          title: const Text(AppConfig.appName),
                          subtitle: const Text(
                            'Щоденник пального та обслуговування',
                          ),
                          trailing: Text('v${AppConfig.version}'),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.lock_outline_rounded),
                          title: Text('Приватність'),
                          subtitle: Text('Дані доступні лише вам'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Акаунт', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text('Вийти з акаунта'),
                          onTap: () => _logout(context, ref),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_forever_outlined,
                            color: AppColors.danger,
                          ),
                          title: const Text(
                            'Видалити обліковий запис',
                            style: TextStyle(color: AppColors.danger),
                          ),
                          subtitle: const Text(
                            'Назавжди видалити всі дані та акаунт',
                          ),
                          onTap: () => context.push('/delete-account'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${AppConfig.appName} • ваш автомобільний щоденник',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
