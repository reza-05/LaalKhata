import 'package:flutter/material.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_layout_widgets.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';

class SourceListTile extends StatelessWidget {
  const SourceListTile({
    super.key,
    required this.source,
    this.trailing,
  });

  final MoneySource source;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProviderLogo(
          sourceName: source.name,
          sourceType: source.type,
          fallbackIcon: source.icon,
          fallbackColor: source.color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                source.type.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              source.balance == null
                  ? 'Balance not set'
                  : formatMoney(source.balance!),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: source.balance == null
                        ? AppColors.mutedInk
                        : AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (source.balance == null)
              Text(
                'Set Manually',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
          ],
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          trailing!,
        ],
      ],
    );
  }
}

class SourcesTab extends StatelessWidget {
  const SourcesTab({
    super.key,
    required this.sources,
    required this.onAddSource,
    required this.onSetBalance,
    required this.onTransfer,
    required this.onArchiveSource,
  });

  final List<MoneySource> sources;
  final VoidCallback onAddSource;
  final ValueChanged<MoneySource> onSetBalance;
  final VoidCallback onTransfer;
  final ValueChanged<MoneySource> onArchiveSource;

  @override
  Widget build(BuildContext context) {
    final activeSources = sources.where((source) => !source.archived).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        PageTitle(
          title: 'Sources',
          subtitle: 'Manage wallets, banks, cards, savings, and custom sources',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                tooltip: 'Transfer between sources',
                onPressed: onTransfer,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAddSource,
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (activeSources.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.altSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: AppColors.mutedInk,
                ),
                const SizedBox(height: 12),
                Text(
                  'No active sources found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a cash wallet, bank, or card to start tracking.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                ),
              ],
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeSources.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final source = activeSources[index];
                  return SourceListTile(
                    source: source,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit balance',
                          onPressed: () => onSetBalance(source),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: 'Archive source',
                          onPressed: () => onArchiveSource(source),
                          icon: const Icon(Icons.archive_outlined),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
