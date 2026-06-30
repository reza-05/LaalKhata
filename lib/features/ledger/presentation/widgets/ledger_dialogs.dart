import 'package:flutter/material.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/domain/source_identity.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';

class AddSourceSheet extends StatefulWidget {
  const AddSourceSheet({
    super.key,
    required this.existingSourceKeys,
  });

  final Set<String> existingSourceKeys;

  @override
  State<AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends State<AddSourceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  SourceType _type = SourceType.cash;
  Color _color = AppColors.primary;

  static const _colors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.positive,
    AppColors.warning,
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              DropdownButtonFormField<SourceType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: SourceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type == null) return;
                  setState(() => _type = type);
                },
              ),
              if (_type == SourceType.cash) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.mutedInk,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Source name',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cash',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Source name',
                    prefixIcon: Icon(Icons.wallet_outlined),
                  ),
                  validator: (value) {
                    final name = (value ?? '').trim();
                    if (name.isEmpty) {
                      return 'Source name is required.';
                    }
                    final identity = sourceIdentityKey(name);
                    if (identity.isEmpty) {
                      return 'Enter a valid source name.';
                    }
                    if (widget.existingSourceKeys.contains(identity)) {
                      return 'This source already exists.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _balanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening balance (optional)',
                  prefixText: '৳ ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) return null;
                  final amount = double.tryParse(trimmed);
                  if (amount == null || amount < 0) {
                    return 'Enter a valid opening balance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Custom color',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _colors
                    .map(
                      (color) => InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == color
                                  ? AppColors.ink
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add),
                label: const Text('Add Source'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final balanceText = _balanceController.text.trim();
    final rawName = _nameController.text.trim();
    final normalizedName = _type == SourceType.cash ? 'Cash' : rawName;

    Navigator.of(context).pop(
      MoneySource(
        name: normalizedName,
        type: _type,
        balance: balanceText.isEmpty ? null : double.parse(balanceText),
        color: _color,
        icon: _type.icon,
      ),
    );
  }
}

class BalanceEditorDialog extends StatefulWidget {
  const BalanceEditorDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialBalance,
  });

  final String title;
  final String confirmLabel;
  final double? initialBalance;

  @override
  State<BalanceEditorDialog> createState() => _BalanceEditorDialogState();
}

class _BalanceEditorDialogState extends State<BalanceEditorDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBalance?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Balance',
          prefixText: '৳ ',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      setState(() => _error = 'Enter a valid balance.');
      return;
    }
    Navigator.of(context).pop(value);
  }
}

class ShortfallDialog extends StatefulWidget {
  const ShortfallDialog({
    super.key,
    required this.source,
    required this.deficit,
    required this.eligibleSources,
  });

  final MoneySource source;
  final double deficit;
  final List<MoneySource> eligibleSources;

  @override
  State<ShortfallDialog> createState() => _ShortfallDialogState();
}

class _ShortfallDialogState extends State<ShortfallDialog> {
  MoneySource? _coverSource;

  @override
  void initState() {
    super.initState();
    if (widget.eligibleSources.isNotEmpty) {
      _coverSource = widget.eligibleSources.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.account_balance_wallet_outlined),
      title: const Text('Balance would fall below zero'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.source.name} would be -${formatMoney(widget.deficit)}. Was this amount covered from another source?',
          ),
          if (widget.eligibleSources.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<MoneySource>(
              initialValue: _coverSource,
              decoration: const InputDecoration(
                labelText: 'Cover from',
                prefixIcon: Icon(Icons.swap_horiz_rounded),
              ),
              items: widget.eligibleSources
                  .map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(
                        '${source.name} (${formatMoney(source.balance ?? 0)})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _coverSource = value),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'No other source has enough balance. You can set this source to zero and keep the expense in history.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            ShortfallResolution(deficit: widget.deficit),
          ),
          child: const Text('Set to Zero'),
        ),
        if (_coverSource != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              ShortfallResolution(
                deficit: widget.deficit,
                coverSource: _coverSource,
              ),
            ),
            child: const Text('Cover Amount'),
          ),
      ],
    );
  }
}

class TransferDialog extends StatefulWidget {
  const TransferDialog({
    super.key,
    required this.sources,
  });

  final List<MoneySource> sources;

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  late MoneySource _from;
  late MoneySource _to;
  final _amountController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _from = widget.sources.first;
    _to = widget.sources[1];
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Between Sources'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MoneySource>(
            initialValue: _from,
            decoration: const InputDecoration(
              labelText: 'From',
              prefixIcon: Icon(Icons.call_made_rounded),
            ),
            items: widget.sources
                .where((source) => source != _to)
                .map(
                  (source) => DropdownMenuItem(
                    value: source,
                    child: Text(source.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _from = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MoneySource>(
            initialValue: _to,
            decoration: const InputDecoration(
              labelText: 'To',
              prefixIcon: Icon(Icons.call_received_rounded),
            ),
            items: widget.sources
                .where((source) => source != _from)
                .map(
                  (source) => DropdownMenuItem(
                    value: source,
                    child: Text(source.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _to = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '৳ ',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Transfer'),
        ),
      ],
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    Navigator.of(context).pop(
      TransferRequest(from: _from, to: _to, amount: amount),
    );
  }
}
