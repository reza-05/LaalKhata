import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/sms/data/sms_suggestion_manager.dart';
import 'package:laalkhata/features/sms/domain/balance_initializer.dart';
import 'package:laalkhata/features/sms/domain/sms_transaction_models.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_dialogs.dart';

class DetectedMessagesSheet extends ConsumerStatefulWidget {
  const DetectedMessagesSheet({
    super.key,
    required this.sources,
    required this.activities,
    required this.onConfirmSuggestion,
    required this.onUseDetectedBalance,
  });

  final List<MoneySource> sources;
  final List<ActivityItem> activities;
  final Future<bool> Function(SmsTransactionSuggestion suggestion)
      onConfirmSuggestion;
  final void Function({
    required String sourceName,
    required double balance,
    required bool wasUnset,
  }) onUseDetectedBalance;

  @override
  ConsumerState<DetectedMessagesSheet> createState() =>
      _DetectedMessagesSheetState();
}

class _DetectedMessagesSheetState extends ConsumerState<DetectedMessagesSheet> {
  var _showIgnored = false;
  String? _message;
  bool _messageIsDanger = false;

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(smsSuggestionManagerProvider.notifier);
    final suggestions = ref.watch(smsSuggestionManagerProvider);
    final pending = suggestions
        .where((item) => item.status == SmsSuggestionStatus.pending)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final ignored = suggestions
        .where((item) => item.status == SmsSuggestionStatus.ignored)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final activeList = _showIgnored ? ignored : pending;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                const IconBubble(
                  icon: Icons.sms_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detected Messages',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SmsPrivacyNotice(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _SecurityMessage(
                message: _message!,
                isDanger: _messageIsDanger,
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text('Pending (${pending.length})'),
                  icon: const Icon(Icons.pending_actions_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Ignored (${ignored.length})'),
                  icon: const Icon(Icons.hide_source_outlined),
                ),
              ],
              selected: {_showIgnored},
              onSelectionChanged: (value) {
                setState(() => _showIgnored = value.first);
              },
            ),
            const SizedBox(height: 16),
            if (activeList.isEmpty)
              const DetectedMessagesEmptyState()
            else
              for (final suggestion in activeList) ...[
                if (_showIgnored)
                  IgnoredSuggestionTile(suggestion: suggestion)
                else
                  SmsSuggestionCard(
                    suggestion: suggestion,
                    sources: widget.sources,
                    currentBalance: _balanceForSource(suggestion.sourceName),
                    onConfirm: (updatedSuggestion) =>
                        _confirmSuggestion(manager, updatedSuggestion),
                    onIgnore: () => _ignoreSuggestion(manager, suggestion.id),
                    onUseDetectedBalance: widget.onUseDetectedBalance,
                  ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  double? _balanceForSource(String sourceName) {
    final source = widget.sources.where(
      (item) => item.name.toLowerCase() == sourceName.toLowerCase(),
    );
    if (source.isEmpty) return null;
    return source.first.balance;
  }

  Future<void> _confirmSuggestion(
    SmsSuggestionManager manager,
    SmsTransactionSuggestion suggestion,
  ) async {
    final confirmed = await widget.onConfirmSuggestion(suggestion);
    if (!confirmed) {
      _showMessage(
        'Transaction was not confirmed. Review the selected source balance.',
        isDanger: true,
      );
      return;
    }
    await manager.removeSuggestion(suggestion.id);
    _showMessage('Transaction confirmed.');
  }

  Future<void> _ignoreSuggestion(
    SmsSuggestionManager manager,
    String id,
  ) async {
    await manager.ignoreSuggestion(id);
    _showMessage('Transaction ignored.');
  }

  void _showMessage(String message, {bool isDanger = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsDanger = isDanger;
    });
  }
}

class SmsPrivacyNotice extends StatelessWidget {
  const SmsPrivacyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SMS is only used locally to suggest transactions. LaalKhata never uploads raw SMS messages.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage({
    required this.message,
    required this.isDanger,
  });

  final String message;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.positive;
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

class DetectedMessagesEmptyState extends StatelessWidget {
  const DetectedMessagesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const IconBubble(
              icon: Icons.mark_chat_unread_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No detected transactions.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmsSuggestionCard extends StatefulWidget {
  const SmsSuggestionCard({
    super.key,
    required this.suggestion,
    required this.sources,
    required this.currentBalance,
    required this.onConfirm,
    required this.onIgnore,
    required this.onUseDetectedBalance,
  });

  final SmsTransactionSuggestion suggestion;
  final List<MoneySource> sources;
  final double? currentBalance;
  final Future<void> Function(SmsTransactionSuggestion suggestion) onConfirm;
  final VoidCallback onIgnore;
  final void Function({
    required String sourceName,
    required double balance,
    required bool wasUnset,
  }) onUseDetectedBalance;

  @override
  State<SmsSuggestionCard> createState() => _SmsSuggestionCardState();
}

class _SmsSuggestionCardState extends State<SmsSuggestionCard> {
  late final TextEditingController _reasonController;
  late final TextEditingController _amountController;
  late String _sourceName;
  late SmsTransactionDirection _direction;
  var _balancePromptDismissed = false;
  final _balanceInitializer = const SmsBalanceInitializer();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.suggestion.reason);
    _amountController = TextEditingController(
      text: widget.suggestion.amount.toStringAsFixed(0),
    );
    _sourceName = widget.suggestion.sourceName;
    _direction = widget.suggestion.direction;
    _reasonController.addListener(_refresh);
    _amountController.addListener(_refresh);
  }

  @override
  void dispose() {
    _reasonController
      ..removeListener(_refresh)
      ..dispose();
    _amountController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final detectedBalance = widget.suggestion.detectedBalance;
    final currentBalance = _currentBalance;
    final canSuggestBalance = !_balancePromptDismissed &&
        _balanceInitializer.canSuggestOpeningBalance(
          suggestion: widget.suggestion,
          currentBalance: currentBalance,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProviderLogo(
                  sourceName: widget.suggestion.sourceName,
                  fallbackIcon: Icons.receipt_long_outlined,
                  fallbackColor: _direction == SmsTransactionDirection.credit
                      ? AppColors.positive
                      : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.suggestion.provider.label} Transaction Detected',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDetectedTime(widget.suggestion.occurredAt),
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
            if (widget.suggestion.duplicateWarning) ...[
              const SizedBox(height: 12),
              const DuplicateWarningBanner(),
            ],
            if (canSuggestBalance && detectedBalance != null) ...[
              const SizedBox(height: 12),
              DetectedBalancePrompt(
                sourceName: _sourceName,
                balance: detectedBalance,
                onUse: () => widget.onUseDetectedBalance(
                  sourceName: _sourceName,
                  balance: detectedBalance,
                  wasUnset: true,
                ),
                onEdit: () => _editDetectedBalance(detectedBalance),
                onIgnore: () => setState(() => _balancePromptDismissed = true),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sourceName,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: _sourceOptions
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(source),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sourceName = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SmsTransactionDirection>(
              initialValue: _direction,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                prefixIcon: Icon(Icons.swap_vert_rounded),
              ),
              items: SmsTransactionDirection.values
                  .map(
                    (direction) => DropdownMenuItem(
                      value: direction,
                      child: Text(direction.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _direction = value);
              },
            ),
            if (detectedBalance != null) ...[
              const SizedBox(height: 12),
              ReadonlyField(
                label: 'Detected Balance',
                value: formatMoney(detectedBalance),
              ),
            ],
            const SizedBox(height: 12),
            BalancePreview(
              currentBalance: currentBalance,
              sourceName: _sourceName,
              amount: amount,
              direction: _direction,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onIgnore,
                    child: const Text('Ignore'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: amount <= 0 ? null : _confirm,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _sourceOptions {
    final names = widget.sources.map((source) => source.name).toList();
    if (!names.any((name) => name.toLowerCase() == _sourceName.toLowerCase())) {
      names.add(_sourceName);
    }
    return names;
  }

  double? get _currentBalance {
    final matches = widget.sources.where(
      (source) => source.name.toLowerCase() == _sourceName.toLowerCase(),
    );
    if (matches.isEmpty) return widget.currentBalance;
    return matches.first.balance;
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text.trim());
    final reason = _reasonController.text.trim();
    if (amount == null || amount <= 0 || reason.isEmpty) return;

    final updated = widget.suggestion.copyWith(
      amount: amount,
      direction: _direction,
      reason: reason,
      sourceName: _sourceName,
    );

    if (widget.suggestion.duplicateWarning) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Possible Duplicate'),
          content: const Text(
            'Similar transaction already exists.\n\nConfirming may create a duplicate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    await widget.onConfirm(updated);
  }

  Future<void> _editDetectedBalance(double detectedBalance) async {
    final edited = await showDialog<double>(
      context: context,
      builder: (context) => BalanceEditorDialog(
        title: 'Edit Detected Balance',
        initialBalance: detectedBalance,
        confirmLabel: 'Use Balance',
      ),
    );

    if (edited == null || edited < 0) return;
    widget.onUseDetectedBalance(
      sourceName: _sourceName,
      balance: edited,
      wasUnset: _currentBalance == null,
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _formatDetectedTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}, $hour:$minute';
  }
}

class DuplicateWarningBanner extends StatelessWidget {
  const DuplicateWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Similar transaction already exists. Confirming may create a duplicate.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class DetectedBalancePrompt extends StatelessWidget {
  const DetectedBalancePrompt({
    super.key,
    required this.sourceName,
    required this.balance,
    required this.onUse,
    required this.onEdit,
    required this.onIgnore,
  });

  final String sourceName;
  final double balance;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.positive.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Possible balance found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$sourceName detected balance: ${formatMoney(balance)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onUse,
                child: const Text('Use Balance'),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: onIgnore,
                child: const Text('Ignore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReadonlyField extends StatelessWidget {
  const ReadonlyField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class BalancePreview extends StatelessWidget {
  const BalancePreview({
    super.key,
    required this.currentBalance,
    required this.sourceName,
    required this.amount,
    required this.direction,
  });

  final double? currentBalance;
  final String sourceName;
  final double amount;
  final SmsTransactionDirection direction;

  @override
  Widget build(BuildContext context) {
    final preview = currentBalance == null
        ? null
        : direction == SmsTransactionDirection.credit
            ? currentBalance! + amount
            : currentBalance! - amount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        preview == null
            ? '$sourceName balance preview: Balance not set'
            : '$sourceName balance preview: ${formatMoney(preview)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class IgnoredSuggestionTile extends StatelessWidget {
  const IgnoredSuggestionTile({
    super.key,
    required this.suggestion,
  });

  final SmsTransactionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hide_source_outlined),
        title: Text(
            '${suggestion.provider.label} ${formatMoney(suggestion.amount)}'),
        subtitle: Text(suggestion.reason),
      ),
    );
  }
}
