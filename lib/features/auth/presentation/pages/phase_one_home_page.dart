import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class PhaseOneHomePage extends ConsumerWidget {
  const PhaseOneHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LaalKhata'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
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
}
