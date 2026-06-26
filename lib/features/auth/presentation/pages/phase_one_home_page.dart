import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class PhaseOneHomePage extends ConsumerStatefulWidget {
  const PhaseOneHomePage({super.key});

  @override
  ConsumerState<PhaseOneHomePage> createState() => _PhaseOneHomePageState();
}

class _PhaseOneHomePageState extends ConsumerState<PhaseOneHomePage> {
  bool _checkedFingerprintSetup = false;
  late Future<_FingerprintSetupStatus> _fingerprintStatusFuture;

  @override
  void initState() {
    super.initState();
    _fingerprintStatusFuture = _loadFingerprintStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offerFingerprintSetup();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LaalKhata'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Phase 1 connected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? 'Signed in',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedInk,
                ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<_FingerprintSetupStatus>(
            future: _fingerprintStatusFuture,
            builder: (context, snapshot) {
              return _FingerprintSetupCard(
                status: snapshot.data,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                onEnable: _enableFingerprintFromCard,
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.burgundy,
                    size: 30,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Next: wallet setup',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cash, bKash, Nagad, and AB Bank accounts will be initialized after authentication.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _offerFingerprintSetup() async {
    if (_checkedFingerprintSetup || !mounted) return;
    _checkedFingerprintSetup = true;

    final service = ref.read(biometricAuthServiceProvider);
    final availability = await service.fingerprintAvailability();
    final enabled = await service.isFingerprintEnabled();
    if (!mounted || !availability.isAvailable || enabled) return;

    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable fingerprint login?'),
          content: const Text(
            'Use fingerprint to unlock LaalKhata on this trusted Android device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );

    if (shouldEnable != true || !mounted) return;

    await _enableFingerprintFromCard();
  }

  Future<_FingerprintSetupStatus> _loadFingerprintStatus() async {
    final service = ref.read(biometricAuthServiceProvider);
    final availability = await service.fingerprintAvailability();
    final enabled = await service.isFingerprintEnabled();
    return _FingerprintSetupStatus(
      enabled: enabled,
      available: availability.isAvailable,
      message: enabled
          ? 'Fingerprint login is enabled for this device.'
          : availability.message,
    );
  }

  Future<void> _enableFingerprintFromCard() async {
    final service = ref.read(biometricAuthServiceProvider);
    final availability = await service.fingerprintAvailability();

    if (!mounted) return;
    if (!availability.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(availability.message)),
      );
      _refreshFingerprintStatus();
      return;
    }

    final result = await service.authenticate(
      reason: 'Confirm fingerprint to enable LaalKhata unlock',
    );

    if (!mounted) return;

    if (result.status == BiometricAuthStatus.success) {
      await service.enableFingerprint();
      if (!mounted) return;
      _refreshFingerprintStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fingerprint login enabled.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? 'Fingerprint setup was not completed.',
        ),
      ),
    );
  }

  void _refreshFingerprintStatus() {
    setState(() {
      _fingerprintStatusFuture = _loadFingerprintStatus();
    });
  }
}

class _FingerprintSetupStatus {
  const _FingerprintSetupStatus({
    required this.enabled,
    required this.available,
    required this.message,
  });

  final bool enabled;
  final bool available;
  final String message;
}

class _FingerprintSetupCard extends StatelessWidget {
  const _FingerprintSetupCard({
    required this.status,
    required this.isLoading,
    required this.onEnable,
  });

  final _FingerprintSetupStatus? status;
  final bool isLoading;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final enabled = status?.enabled ?? false;
    final available = status?.available ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.income.withValues(alpha: 0.1)
                    : AppColors.burgundy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                enabled ? Icons.verified_user_outlined : Icons.fingerprint,
                color: enabled ? AppColors.income : AppColors.burgundy,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled ? 'Fingerprint ready' : 'Fingerprint login',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading
                        ? 'Checking this Android device...'
                        : status?.message ??
                            'Enable quick unlock for this trusted device.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          height: 1.35,
                        ),
                  ),
                  if (!enabled) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : onEnable,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(
                        available
                            ? 'Enable fingerprint login'
                            : 'Check fingerprint',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
