import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/auth_validator.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/laalkhata_mark.dart';

class ResetPasswordRequestPage extends ConsumerStatefulWidget {
  const ResetPasswordRequestPage({super.key});

  @override
  ConsumerState<ResetPasswordRequestPage> createState() =>
      _ResetPasswordRequestPageState();
}

class _ResetPasswordRequestPageState
    extends ConsumerState<ResetPasswordRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
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
                            'Recover your account',
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
                            'Enter your IUT email. We will send a secure password reset link.',
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
                            _ResetMessage(
                              message: authState.message!,
                              color: authState.status == AuthStatus.error
                                  ? AppColors.danger
                                  : AppColors.positive,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'IUT email',
                              hintText: 'name@iut-dhaka.edu',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (value) =>
                                AuthValidator.validateIutEmail(value ?? ''),
                            onFieldSubmitted: (_) => _sendResetLink(),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _sendResetLink,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.mark_email_read_outlined),
                            label: const Text('Send Reset Link'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Back to Login'),
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

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).sendPasswordReset(
          email: _emailController.text,
        );
  }
}

class _ResetMessage extends StatelessWidget {
  const _ResetMessage({
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
