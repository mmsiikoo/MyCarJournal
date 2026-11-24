import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/error_messages.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_router_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_snack.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;
      if (user.emailVerified) {
        _check();
      } else {
        _resend(showSnack: false);
      }
    });
  }

  Future<void> _resend({bool showSnack = true}) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    if (user.emailVerified) {
      await _check();
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      setState(() => _sent = true);
      if (showSnack) {
        showAppSnack(context, 'Лист надіслано повторно');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await ref.read(authRouterNotifierProvider).refreshUser();
      if (!mounted) return;
      final verified =
          ref.read(authRepositoryProvider).currentUser?.emailVerified ?? false;
      if (verified) {
        showAppSnack(context, 'Email підтверджено');
        context.go('/');
      } else {
        showAppSnack(
          context,
          'Email ще не підтверджено. Перевірте пошту.',
          error: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, authErrorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '—';
    final busy = _sending || _checking;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Підтвердження email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const AppLogo(size: 76),
                  const SizedBox(height: 20),
                  Text(
                    'Підтвердіть пошту',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sent
                        ? 'Лист надіслано на $email. Перейдіть за посиланням у листі, щоб активувати акаунт.'
                        : 'Надішлемо лист на $email, щоб підтвердити акаунт.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mark_email_read_outlined,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Перевірте папку «Спам», якщо лист не з’явився протягом кількох хвилин.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: busy ? null : _check,
                            icon: _checking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _checking ? 'Перевіряємо…' : 'Я підтвердив',
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => _resend(),
                            icon: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(
                              _sending
                                  ? 'Надсилаємо…'
                                  : 'Надіслати лист ще раз',
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: busy ? null : _signOut,
                            child: const Text('Вийти з акаунта'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => context.push('/delete-account'),
                    icon: const Icon(Icons.delete_forever_outlined),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    label: const Text('Видалити акаунт'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Якщо email вказано помилково, видаліть акаунт і зареєструйтеся знову.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
