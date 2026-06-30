import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/sms/domain/sms_transaction_models.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_layout_widgets.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/sources_tab.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.totalBalance,
    required this.balanceVisible,
    required this.onBalanceTap,
    required this.sources,
    required this.activities,
    required this.balanceSuggestions,
    required this.onViewSources,
    required this.onViewActivities,
    required this.onSetBalance,
    required this.onUseSuggestedBalance,
    required this.onEditSuggestedBalance,
    required this.onIgnoreSuggestedBalance,
  });

  final String userName;
  final String userEmail;
  final double totalBalance;
  final bool balanceVisible;
  final VoidCallback onBalanceTap;
  final List<MoneySource> sources;
  final List<ActivityItem> activities;
  final List<SmsBalanceSuggestion> balanceSuggestions;
  final VoidCallback onViewSources;
  final VoidCallback onViewActivities;
  final ValueChanged<MoneySource> onSetBalance;
  final ValueChanged<SmsBalanceSuggestion> onUseSuggestedBalance;
  final ValueChanged<SmsBalanceSuggestion> onEditSuggestedBalance;
  final ValueChanged<SmsBalanceSuggestion> onIgnoreSuggestedBalance;

  @override
  Widget build(BuildContext context) {
    final previewSources = sources.take(4).toList();
    final hasMoreSources = sources.length > previewSources.length;
    final hasMoreActivities = activities.length > 6;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        HomeHeader(
          userName: userName,
          userEmail: userEmail,
          totalBalance: totalBalance,
          balanceVisible: balanceVisible,
          onBalanceTap: onBalanceTap,
        ),
        const SizedBox(height: 18),
        if (balanceSuggestions.isNotEmpty) ...[
          OpeningBalanceSuggestionsCard(
            suggestions: balanceSuggestions,
            onUse: onUseSuggestedBalance,
            onEdit: onEditSuggestedBalance,
            onIgnore: onIgnoreSuggestedBalance,
          ),
          const SizedBox(height: 18),
        ],
        SectionHeader(
          title: 'Active Sources',
          actionLabel: hasMoreSources ? 'View All' : null,
          onAction: hasMoreSources ? onViewSources : null,
        ),
        const SizedBox(height: 10),
        ActiveSourcesCard(
          sources: previewSources,
          onSetBalance: onSetBalance,
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Recent Activity',
          actionLabel: hasMoreActivities ? 'View All' : null,
          onAction: hasMoreActivities ? onViewActivities : null,
        ),
        const SizedBox(height: 10),
        RecentActivityCard(
          activities: activities,
          maxItems: hasMoreActivities ? 6 : activities.length,
        ),
      ],
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.totalBalance,
    required this.balanceVisible,
    required this.onBalanceTap,
  });

  final String userName;
  final String userEmail;
  final double totalBalance;
  final bool balanceVisible;
  final VoidCallback onBalanceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GlassBalanceCard(
                    visible: balanceVisible,
                    amount: totalBalance,
                    onTap: onBalanceTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassBalanceCard extends StatelessWidget {
  const GlassBalanceCard({
    super.key,
    required this.visible,
    required this.amount,
    required this.onTap,
  });

  final bool visible;
  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: visible
                    ? Row(
                        key: const ValueKey('visible-balance'),
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Balance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatMoney(amount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white,
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('hidden-balance'),
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap for Balance',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OpeningBalanceSuggestionsCard extends StatelessWidget {
  const OpeningBalanceSuggestionsCard({
    super.key,
    required this.suggestions,
    required this.onUse,
    required this.onEdit,
    required this.onIgnore,
  });

  final List<SmsBalanceSuggestion> suggestions;
  final ValueChanged<SmsBalanceSuggestion> onUse;
  final ValueChanged<SmsBalanceSuggestion> onEdit;
  final ValueChanged<SmsBalanceSuggestion> onIgnore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBubble(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Possible balances found',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review before adding. Nothing changes automatically.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final suggestion in suggestions) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.altSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    ProviderLogo(
                      sourceName: suggestion.sourceName,
                      fallbackIcon: Icons.account_balance_wallet_outlined,
                      fallbackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.sourceName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatMoney(suggestion.balance),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit balance',
                      onPressed: () => onEdit(suggestion),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    TextButton(
                      onPressed: () => onIgnore(suggestion),
                      child: const Text('Ignore'),
                    ),
                    FilledButton(
                      onPressed: () => onUse(suggestion),
                      child: const Text('Use'),
                    ),
                  ],
                ),
              ),
              if (suggestion != suggestions.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class ActiveSourcesCard extends StatelessWidget {
  const ActiveSourcesCard({
    super.key,
    required this.sources,
    required this.onSetBalance,
  });

  final List<MoneySource> sources;
  final ValueChanged<MoneySource> onSetBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final source in sources) ...[
              SourceListTile(
                source: source,
                trailing: IconButton(
                  tooltip: 'Edit balance',
                  onPressed: () => onSetBalance(source),
                  icon: const Icon(Icons.edit_rounded),
                ),
              ),
              if (source != sources.last) const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.activities,
    this.maxItems = 6,
  });

  final List<ActivityItem> activities;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.altSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.mutedInk,
            ),
            const SizedBox(height: 10),
            Text(
              'No activities recorded yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Add transactions manually or import them from SMS.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
          ],
        ),
      );
    }

    final visibleActivities = activities.take(maxItems).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final activity in visibleActivities) ...[
              Row(
                children: [
                  IconBubble(
                    icon: activity.icon,
                    color: activity.amount >= 0
                        ? AppColors.positive
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activity.source} • ${activity.time}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    activity.type == 'transfer'
                        ? formatMoney(activity.amount)
                        : activity.amount == 0
                            ? 'Recorded'
                            : '${activity.amount >= 0 ? '+' : '-'}${formatMoney(activity.amount.abs())}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: activity.type == 'transfer' ||
                                  activity.amount == 0
                              ? AppColors.mutedInk
                              : activity.amount >= 0
                                  ? AppColors.positive
                                  : AppColors.danger,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              if (activity != visibleActivities.last) const Divider(height: 22),
            ],
          ],
        ),
      ),
    );
  }
}
