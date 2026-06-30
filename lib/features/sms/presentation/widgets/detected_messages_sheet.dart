import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/sms/data/sms_suggestion_manager.dart';
import 'package:laalkhata/features/sms/domain/sms_transaction_models.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';

class DetectedMessagesSheet extends ConsumerStatefulWidget {
  const DetectedMessagesSheet({
    super.key,
    required this.sources,
    required this.activities,
    required this.onConfirmSuggestion,
  });

  final List<MoneySource> sources;
  final List<ActivityItem> activities;
  final Future<bool> Function(SmsTransactionSuggestion suggestion)
      onConfirmSuggestion;

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
  });

  final SmsTransactionSuggestion suggestion;
  final List<MoneySource> sources;
  final double? currentBalance;
  final Future<void> Function(SmsTransactionSuggestion suggestion) onConfirm;
  final VoidCallback onIgnore;

  @override
  State<SmsSuggestionCard> createState() => _SmsSuggestionCardState();
}

class _SmsSuggestionCardState extends State<SmsSuggestionCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _showReviewSheet,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProviderLogo(
                    sourceName: widget.suggestion.sourceName,
                    fallbackIcon: Icons.receipt_long_outlined,
                    fallbackColor: widget.suggestion.direction ==
                            SmsTransactionDirection.credit
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedInk,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    icon: widget.suggestion.direction ==
                            SmsTransactionDirection.credit
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    label: widget.suggestion.direction.label,
                  ),
                  _SummaryChip(
                    icon: Icons.payments_outlined,
                    label: formatMoney(widget.suggestion.amount),
                    highlight: true,
                  ),
                  _SummaryChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: widget.suggestion.sourceName,
                  ),
                ],
              ),
              if (widget.suggestion.detectedBalance != null) ...[
                const SizedBox(height: 10),
                _CompactInfoRow(
                  icon: Icons.account_balance_rounded,
                  label:
                      'Detected balance: ${formatMoney(widget.suggestion.detectedBalance!)}',
                ),
              ],
              if (widget.suggestion.duplicateWarning) ...[
                const SizedBox(height: 10),
                const DuplicateWarningBanner(compact: true),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to review',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDetectedTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}, $hour:$minute';
  }

  Future<void> _showReviewSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _SuggestionReviewSheet(
          suggestion: widget.suggestion,
          sources: widget.sources,
          currentBalance: widget.currentBalance,
          onConfirm: widget.onConfirm,
          onIgnore: widget.onIgnore,
        ),
      ),
    );
  }
}

class DuplicateWarningBanner extends StatelessWidget {
  const DuplicateWarningBanner({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: compact ? 18 : 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Similar transaction already exists. Confirming may create a duplicate.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    height: compact ? 1.25 : 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionReviewSheet extends StatefulWidget {
  const _SuggestionReviewSheet({
    required this.suggestion,
    required this.sources,
    required this.currentBalance,
    required this.onConfirm,
    required this.onIgnore,
  });

  final SmsTransactionSuggestion suggestion;
  final List<MoneySource> sources;
  final double? currentBalance;
  final Future<void> Function(SmsTransactionSuggestion suggestion) onConfirm;
  final VoidCallback onIgnore;

  @override
  State<_SuggestionReviewSheet> createState() => _SuggestionReviewSheetState();
}

class _SuggestionReviewSheetState extends State<_SuggestionReviewSheet> {
  late final TextEditingController _reasonController;
  late final TextEditingController _amountController;
  late String _sourceName;
  late SmsTransactionDirection _direction;

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

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProviderLogo(
                          sourceName: widget.suggestion.sourceName,
                          fallbackIcon: Icons.receipt_long_outlined,
                          fallbackColor: widget.suggestion.direction ==
                                  SmsTransactionDirection.credit
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review the details before saving this transaction.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.mutedInk,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ReviewSummaryCard(
                      sourceName: _sourceName,
                      direction: _direction,
                      amount: amount,
                      detectedBalance: detectedBalance,
                      occurredAt: widget.suggestion.occurredAt,
                    ),
                    if (widget.suggestion.duplicateWarning) ...[
                      const SizedBox(height: 12),
                      const DuplicateWarningBanner(compact: true),
                    ],
                    const SizedBox(height: 14),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          'Edit Details',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        subtitle: Text(
                          'Reason, source, amount, and type',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        children: [
                          const SizedBox(height: 12),
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
                              prefixIcon:
                                  Icon(Icons.account_balance_wallet_outlined),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BalancePreview(
                      currentBalance: _currentBalance,
                      sourceName: _sourceName,
                      amount: amount,
                      direction: _direction,
                      detectedBalance: detectedBalance,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _ignore,
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
      if (shouldContinue != true || !mounted) return;
    }

    await widget.onConfirm(updated);
    if (mounted) Navigator.of(context).pop();
  }

  void _ignore() {
    widget.onIgnore();
    Navigator.of(context).pop();
  }

  void _refresh() {
    if (mounted) setState(() {});
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
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
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
    this.detectedBalance,
  });

  final double? currentBalance;
  final String sourceName;
  final double amount;
  final SmsTransactionDirection direction;
  final double? detectedBalance;

  @override
  Widget build(BuildContext context) {
    final preview = detectedBalance ??
        (currentBalance == null
            ? null
            : direction == SmsTransactionDirection.credit
                ? currentBalance! + amount
                : currentBalance! - amount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        detectedBalance != null
            ? '$sourceName balance after confirm: ${formatMoney(detectedBalance!)}'
            : preview == null
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.altSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? AppColors.primary : AppColors.mutedInk,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({
    required this.sourceName,
    required this.direction,
    required this.amount,
    required this.detectedBalance,
    required this.occurredAt,
  });

  final String sourceName;
  final SmsTransactionDirection direction;
  final double amount;
  final double? detectedBalance;
  final DateTime occurredAt;

  @override
  Widget build(BuildContext context) {
    final hour = occurredAt.hour.toString().padLeft(2, '0');
    final minute = occurredAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Source: $sourceName',
          ),
          const SizedBox(height: 10),
          _CompactInfoRow(
            icon: direction == SmsTransactionDirection.credit
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
            label: 'Transaction type: ${direction.label}',
          ),
          const SizedBox(height: 10),
          _CompactInfoRow(
            icon: Icons.payments_outlined,
            label: 'Amount: ${formatMoney(amount)}',
          ),
          if (detectedBalance != null) ...[
            const SizedBox(height: 10),
            _CompactInfoRow(
              icon: Icons.account_balance_rounded,
              label: 'Detected balance: ${formatMoney(detectedBalance!)}',
            ),
          ],
          const SizedBox(height: 10),
          _CompactInfoRow(
            icon: Icons.schedule_rounded,
            label:
                'Date & time: ${occurredAt.day}/${occurredAt.month}/${occurredAt.year}, $hour:$minute',
          ),
        ],
      ),
    );
  }
}
