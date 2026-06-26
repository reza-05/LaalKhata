import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/services/local_pin_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/laalkhata_mark.dart';

class PinUnlockPage extends ConsumerStatefulWidget {
  const PinUnlockPage({
    super.key,
    required this.onUnlocked,
  });

  final VoidCallback onUnlocked;

  @override
  ConsumerState<PinUnlockPage> createState() => _PinUnlockPageState();
}

class _PinUnlockPageState extends ConsumerState<PinUnlockPage> {
  final _pinController = TextEditingController();
  bool _isChecking = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryFingerprint(auto: true);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LaalKhataMark(),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primary,
                          size: 54,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Unlock LaalKhata',
                          textAlign: TextAlign.center,
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
                          'Use your local PIN or fingerprint on this device.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.mutedInk,
                                    height: 1.35,
                                  ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        TextField(
                          controller: _pinController,
                          obscureText: true,
                          maxLength: 5,
                          enabled: !_isChecking,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          decoration: const InputDecoration(
                            labelText: '5-digit PIN',
                            counterText: '',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          onSubmitted: (_) => _verifyPin(),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _isChecking ? null : _verifyPin,
                          icon: _isChecking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.lock_open_rounded),
                          label: const Text('Unlock'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              _isChecking ? null : () => _tryFingerprint(),
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Use fingerprint'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isChecking
                              ? null
                              : () => ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(),
                          child: const Text('Sign out'),
                        ),
                      ],
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

  Future<void> _verifyPin() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    final result =
        await ref.read(localPinServiceProvider).verifyPin(_pinController.text);
    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    switch (result.status) {
      case PinVerifyStatus.success:
        widget.onUnlocked();
        break;
      case PinVerifyStatus.locked:
        setState(() {
          _message =
              'Too many failed attempts. Try again in ${_formatDuration(result.lockedFor)}.';
        });
        break;
      case PinVerifyStatus.failed:
        setState(() {
          _message = result.message ?? 'PIN did not match.';
        });
        break;
    }
  }

  Future<void> _tryFingerprint({bool auto = false}) async {
    final service = ref.read(biometricAuthServiceProvider);
    final enabled = await service.isFingerprintEnabled();
    if (!enabled) {
      if (!auto && mounted) {
        setState(() {
          _message = 'Fingerprint unlock is not enabled on this device.';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isChecking = true;
      _message = null;
    });

    final result = await service.authenticate(
      reason: 'Use fingerprint to unlock LaalKhata',
    );
    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    switch (result.status) {
      case BiometricAuthStatus.success:
        widget.onUnlocked();
        break;
      case BiometricAuthStatus.locked:
        setState(() {
          _message =
              'Too many fingerprint attempts. Try again in ${_formatDuration(result.lockedFor)}.';
        });
        break;
      case BiometricAuthStatus.unavailable:
      case BiometricAuthStatus.failed:
        if (!auto) {
          setState(() {
            _message = result.message ?? 'Fingerprint did not match.';
          });
        }
        break;
    }
  }

  String _formatDuration(Duration? duration) {
    final value = duration ?? Duration.zero;
    if (value.inMinutes >= 1) return '${value.inMinutes} min';
    return '${value.inSeconds} sec';
  }
}
