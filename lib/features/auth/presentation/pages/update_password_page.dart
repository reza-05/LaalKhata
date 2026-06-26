import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/password_recovery_signal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/auth_validator.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/laalkhata_mark.dart';

class UpdatePasswordPage extends ConsumerStatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  ConsumerState<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends ConsumerState<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordHints);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordHints);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refreshPasswordHints() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LaalKhataMark(),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        const BoxShadow(
                          color: AppColors.subtleShadow,
                          blurRadius: 28,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Set new password',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a strong password to finish account recovery.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.mutedInk,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 18),
                          if (authState.message != null) ...[
                            _UpdateMessage(
                              message: authState.message!,
                              color: authState.status == AuthStatus.error
                                  ? AppColors.danger
                                  : AppColors.positive,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'New password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _passwordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                AuthValidator.validateStrongPassword(
                              value ?? '',
                              name: '',
                              email: '',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PasswordHint(password: _passwordController.text),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_confirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon:
                                  const Icon(Icons.lock_person_outlined),
                              suffixIcon: IconButton(
                                tooltip: _confirmPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () {
                                  setState(() {
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible;
                                  });
                                },
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Confirm password is required.';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _updatePassword(),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _updatePassword,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.verified_user_outlined),
                            label: const Text('Update Password'),
                          ),
                        ],
                      ),
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

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).updatePassword(
          password: _passwordController.text,
        );

    final status = ref.read(authControllerProvider).status;
    if (!mounted || status == AuthStatus.error) return;

    PasswordRecoverySignal.clear();
  }
}

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = [
      _PasswordCheck('8+ characters', password.length >= 8),
      _PasswordCheck('Uppercase', RegExp(r'[A-Z]').hasMatch(password)),
      _PasswordCheck('Lowercase', RegExp(r'[a-z]').hasMatch(password)),
      _PasswordCheck('Number', RegExp(r'\d').hasMatch(password)),
      _PasswordCheck(
        'Special',
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`/\\;[\]]').hasMatch(password),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: checks
          .map(
            (check) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: check.passed
                    ? AppColors.positive.withValues(alpha: 0.1)
                    : AppColors.line.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                check.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: check.passed
                          ? AppColors.positive
                          : AppColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PasswordCheck {
  const _PasswordCheck(this.label, this.passed);

  final String label;
  final bool passed;
}

class _UpdateMessage extends StatelessWidget {
  const _UpdateMessage({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
