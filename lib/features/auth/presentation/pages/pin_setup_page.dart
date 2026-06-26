import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/laalkhata_mark.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _enableFingerprint = false;
  bool _isSaving = false;
  String? _message;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            'Secure this device',
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
                            'Set a 5-digit local PIN. It stays only on this phone.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.mutedInk,
                                  height: 1.35,
                                ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 16),
                            _PinMessage(message: _message!),
                          ],
                          const SizedBox(height: 18),
                          _PinField(
                            controller: _pinController,
                            label: '5-digit PIN',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _PinField(
                            controller: _confirmPinController,
                            label: 'Confirm PIN',
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                            validator: (value) {
                              final pin = value ?? '';
                              if (!RegExp(r'^\d{5}$').hasMatch(pin)) {
                                return 'Enter a 5-digit PIN.';
                              }
                              if (pin != _pinController.text) {
                                return 'PINs do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          FutureBuilder<FingerprintAvailability>(
                            future: ref
                                .read(biometricAuthServiceProvider)
                                .fingerprintAvailability(),
                            builder: (context, snapshot) {
                              final available =
                                  snapshot.data?.isAvailable ?? false;
                              return SwitchListTile(
                                value: available && _enableFingerprint,
                                onChanged: available
                                    ? (value) {
                                        setState(() {
                                          _enableFingerprint = value;
                                        });
                                      }
                                    : null,
                                title: const Text('Enable fingerprint unlock'),
                                subtitle: Text(
                                  available
                                      ? 'Optional. PIN will still work.'
                                      : snapshot.data?.message ??
                                          'Checking fingerprint availability...',
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_outline_rounded),
                            label: const Text('Save PIN'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await ref.read(localPinServiceProvider).setPin(_pinController.text);

      if (_enableFingerprint) {
        final biometricService = ref.read(biometricAuthServiceProvider);
        final result = await biometricService.authenticate(
          reason: 'Confirm fingerprint to enable LaalKhata unlock',
        );

        if (result.status == BiometricAuthStatus.success) {
          await biometricService.enableFingerprint();
        } else if (mounted) {
          setState(() {
            _message = result.message ??
                'PIN saved. Fingerprint setup was not completed.';
          });
        }
      }

      if (!mounted) return;
      widget.onCompleted();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'PIN setup could not be completed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      maxLength: 5,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: const Icon(Icons.pin_outlined),
      ),
      validator: validator ??
          (value) {
            if (!RegExp(r'^\d{5}$').hasMatch(value ?? '')) {
              return 'Enter a 5-digit PIN.';
            }
            return null;
          },
      onFieldSubmitted: onSubmitted,
    );
  }
}

class _PinMessage extends StatelessWidget {
  const _PinMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
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
