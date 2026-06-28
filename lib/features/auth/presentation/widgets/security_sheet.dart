import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/core/services/biometric_auth_service.dart';
import 'package:laalkhata/core/services/local_pin_service.dart';
import 'package:laalkhata/features/auth/presentation/controllers/auth_controller.dart';

class SecuritySheet extends ConsumerStatefulWidget {
  const SecuritySheet({super.key});

  @override
  ConsumerState<SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends ConsumerState<SecuritySheet> {
  bool _isBusy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final biometricService = ref.read(biometricAuthServiceProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: FutureBuilder<(bool, FingerprintAvailability)>(
        future: _loadSecurityState(),
        builder: (context, snapshot) {
          final fingerprintEnabled = snapshot.data?.$1 ?? false;
          final availability = snapshot.data?.$2;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Security',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your PIN stays local on this phone. Keep at least one unlock method active.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.4,
                    ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                _SecurityMessage(message: _message!),
              ],
              const SizedBox(height: 18),
              SecurityActionTile(
                icon: Icons.pin_outlined,
                title: 'Local PIN',
                subtitle: 'Enabled. Change your 5-digit PIN.',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _isBusy ? null : _openChangePinSheet,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: SwitchListTile(
                  value: fingerprintEnabled,
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          if (value) {
                            _enableFingerprint(
                              biometricService,
                              availability,
                            );
                          } else {
                            _disableFingerprint(biometricService);
                          }
                        },
                  title: const Text('Fingerprint unlock'),
                  subtitle: Text(
                    fingerprintEnabled
                        ? 'Enabled on this device.'
                        : availability == null
                            ? 'Checking fingerprint availability...'
                            : availability.isAvailable
                                ? 'Off. Turn on after fingerprint confirmation.'
                                : availability.message,
                  ),
                  secondary: const Icon(Icons.fingerprint_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'PIN cannot be removed because LaalKhata needs at least one local unlock method.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.35,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<(bool, FingerprintAvailability)> _loadSecurityState() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    final enabled = await biometricService.isFingerprintEnabled();
    final availability = await biometricService.fingerprintAvailability();
    return (enabled, availability);
  }

  Future<void> _openChangePinSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const ChangePinSheet(),
    );

    if (!mounted || changed != true) return;
    setState(() {
      _message = 'PIN changed successfully.';
    });
  }

  Future<void> _enableFingerprint(
    BiometricAuthService service,
    FingerprintAvailability? availability,
  ) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final ready = availability ?? await service.fingerprintAvailability();
      if (!ready.isAvailable) {
        setState(() {
          _message = ready.message;
        });
        return;
      }

      final result = await service.authenticate(
        reason: 'Confirm fingerprint to enable LaalKhata unlock',
      );

      if (result.status == BiometricAuthStatus.success) {
        await service.enableFingerprint();
        if (!mounted) return;
        setState(() {
          _message = 'Fingerprint unlock enabled.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _message = result.message ?? 'Fingerprint setup was not completed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _disableFingerprint(BiometricAuthService service) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await service.disableFingerprint();
      if (!mounted) return;
      setState(() {
        _message = 'Fingerprint unlock disabled. PIN unlock remains active.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
}

class ChangePinSheet extends ConsumerStatefulWidget {
  const ChangePinSheet({super.key});

  @override
  ConsumerState<ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;
  String? _message;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your current PIN before setting a new 5-digit PIN.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.4,
                  ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              _SecurityMessage(message: _message!, isDanger: true),
            ],
            const SizedBox(height: 18),
            SecurityPinField(
              controller: _currentPinController,
              label: 'Current PIN',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            SecurityPinField(
              controller: _newPinController,
              label: 'New PIN',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            SecurityPinField(
              controller: _confirmPinController,
              label: 'Confirm new PIN',
              textInputAction: TextInputAction.done,
              validator: (value) {
                final pin = value ?? '';
                if (!RegExp(r'^\d{5}$').hasMatch(pin)) {
                  return 'Enter a 5-digit PIN.';
                }
                if (pin != _newPinController.text) {
                  return 'PINs do not match.';
                }
                return null;
              },
              onSubmitted: (_) => _changePin(),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _changePin,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save New PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final service = ref.read(localPinServiceProvider);
    final result = await service.verifyPin(_currentPinController.text);
    if (!mounted) return;

    if (result.status != PinVerifyStatus.success) {
      setState(() {
        _isSaving = false;
        _message = result.status == PinVerifyStatus.locked
            ? 'Too many failed attempts. Try again in ${_formatDuration(result.lockedFor)}.'
            : result.message ?? 'Current PIN did not match.';
      });
      return;
    }

    try {
      await service.setPin(_newPinController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'PIN could not be changed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDuration(Duration? duration) {
    final value = duration ?? Duration.zero;
    if (value.inMinutes >= 1) return '${value.inMinutes} min';
    return '${value.inSeconds} sec';
  }
}

class SecurityPinField extends StatelessWidget {
  const SecurityPinField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

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

class SecurityActionTile extends StatelessWidget {
  const SecurityActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                          ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage({
    super.key,
    required this.message,
    this.isDanger = false,
  });

  final String message;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
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
