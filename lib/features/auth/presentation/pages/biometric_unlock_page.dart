import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/laalkhata_mark.dart';

class BiometricUnlockPage extends ConsumerStatefulWidget {
  const BiometricUnlockPage({
    super.key,
    required this.onUnlocked,
  });

  final VoidCallback onUnlocked;

  @override
  ConsumerState<BiometricUnlockPage> createState() =>
      _BiometricUnlockPageState();
}

class _BiometricUnlockPageState extends ConsumerState<BiometricUnlockPage> {
  String? _message;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unlock();
    });
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
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.burgundy,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock LaalKhata',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use your fingerprint to open this trusted device.',
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
                                  color: AppColors.expense,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: _isChecking ? null : _unlock,
                          icon: _isChecking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded),
                          label: const Text('Use fingerprint'),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isChecking
                              ? null
                              : () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .signOut();
                                },
                          child: const Text('Use password instead'),
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

  Future<void> _unlock() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    final service = ref.read(biometricAuthServiceProvider);
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
              'Too many failed attempts. Try again in ${_formatDuration(result.lockedFor)}.';
        });
        break;
      case BiometricAuthStatus.unavailable:
        setState(() {
          _message = result.message ?? 'Fingerprint is unavailable.';
        });
        break;
      case BiometricAuthStatus.failed:
        setState(() {
          _message = result.message ?? 'Fingerprint did not match.';
        });
        break;
    }
  }

  String _formatDuration(Duration? duration) {
    final value = duration ?? Duration.zero;
    if (value.inMinutes >= 1) return '${value.inMinutes} min';
    return '${value.inSeconds} sec';
  }
}
