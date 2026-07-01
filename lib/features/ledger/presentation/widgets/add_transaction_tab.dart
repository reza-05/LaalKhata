import 'package:flutter/material.dart';

import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_layout_widgets.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';

class AddTransactionTab extends StatefulWidget {
  const AddTransactionTab({
    super.key,
    required this.sources,
    required this.onSave,
    required this.onAddSource,
  });

  final List<MoneySource> sources;
  final Future<bool> Function(ManualEntry entry) onSave;
  final Future<void> Function() onAddSource;

  @override
  State<AddTransactionTab> createState() => _AddTransactionTabState();
}

class _AddTransactionTabState extends State<AddTransactionTab>
    with TickerProviderStateMixin {
  static const _commonTypes = [
    EntryType.expense,
    EntryType.income,
    EntryType.transfer,
  ];

  static const _lessCommonTypes = [
    EntryType.lent,
    EntryType.borrowed,
    EntryType.project,
    EntryType.balanceAdjustment,
  ];

  static const _categories = [
    _CategoryOption('Food', Icons.restaurant_outlined),
    _CategoryOption('Transport', Icons.directions_bus_rounded),
    _CategoryOption('Education', Icons.school_outlined),
    _CategoryOption('Shopping', Icons.shopping_bag_outlined),
    _CategoryOption('Bills', Icons.receipt_long_outlined),
    _CategoryOption('Health', Icons.favorite_outline_rounded),
    _CategoryOption('Others', Icons.more_horiz_rounded),
  ];

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _personController = TextEditingController();
  final _projectController = TextEditingController();
  final _itemController = TextEditingController();

  EntryType _type = EntryType.expense;
  String? _sourceName;
  String? _destinationSourceName;
  String _category = 'Others';
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _saving = false;
  bool _showMoreOptions = false;

  @override
  void initState() {
    super.initState();
    _syncSourceSelection();
  }

  @override
  void didUpdateWidget(covariant AddTransactionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSourceSelection();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _personController.dispose();
    _projectController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  List<MoneySource> get _activeSources =>
      widget.sources.where((source) => !source.archived).toList();

  List<String> get _sourceNames =>
      _activeSources.map((source) => source.name).toList();

  bool get _needsCategory =>
      _type == EntryType.expense || _type == EntryType.income;

  bool get _isLessCommonType => _lessCommonTypes.contains(_type);

  double? get _parsedAmount => double.tryParse(_amountController.text.trim());

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreviewRows();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          children: [
            const PageTitle(
              title: 'New Transaction',
              subtitle: 'Add a new financial record.',
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionCaption(
                        title: 'Transaction type',
                        subtitle: 'Pick the kind of record you want to add.',
                      ),
                      const SizedBox(height: 10),
                      _EntryTypeSelector(
                        selected: _type,
                        onSelected: _onTypeChanged,
                        onOpenMore: _showMoreTypesSheet,
                      ),
                      if (_isLessCommonType) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            label: Text(_type.label),
                            avatar: Icon(
                              _entryTypeIcon(_type),
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_type),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ..._buildTypeAwareFields(context),
                                if (preview.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _PreviewCard(rows: preview),
                                ],
                                if (_hasAdditionalDetails) ...[
                                  const SizedBox(height: 14),
                                  _buildAdditionalDetailsSection(),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 12,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.subtleShadow,
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Transaction'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTypeAwareFields(BuildContext context) {
    switch (_type) {
      case EntryType.expense:
      case EntryType.income:
        return [
          _buildReasonField(
            label: 'Reason',
            hint: _type == EntryType.expense
                ? 'What did you spend on?'
                : 'What income did you receive?',
          ),
          const SizedBox(height: 12),
          _buildSourceField(label: 'Source', sourceName: _sourceName),
          const SizedBox(height: 12),
          _buildAmountField(label: 'Amount'),
          const SizedBox(height: 12),
          _buildCategoryField(),
        ];
      case EntryType.transfer:
        return [
          _buildSourceField(
            label: 'From Source',
            sourceName: _sourceName,
          ),
          const SizedBox(height: 12),
          _buildSourceField(
            label: 'To Source',
            sourceName: _destinationSourceName,
            excludeSourceName: _sourceName,
            isDestination: true,
            validationMessage: 'Please choose both sources.',
          ),
          const SizedBox(height: 12),
          _buildAmountField(label: 'Amount'),
        ];
      case EntryType.lent:
      case EntryType.borrowed:
        return [
          _buildPersonField(),
          const SizedBox(height: 12),
          _buildSourceField(label: 'Source', sourceName: _sourceName),
          const SizedBox(height: 12),
          _buildAmountField(label: 'Amount'),
        ];
      case EntryType.project:
        return [
          _buildProjectField(),
          const SizedBox(height: 12),
          _buildItemField(),
          const SizedBox(height: 12),
          _buildSourceField(label: 'Source', sourceName: _sourceName),
          const SizedBox(height: 12),
          _buildAmountField(label: 'Amount'),
        ];
      case EntryType.balanceAdjustment:
        return [
          _AdjustmentInfoCard(source: _selectedSource),
          const SizedBox(height: 12),
          _buildSourceField(label: 'Source', sourceName: _sourceName),
          const SizedBox(height: 12),
          _buildBalanceReadOnlyField(),
          const SizedBox(height: 12),
          _buildAmountField(
            label: 'New Balance',
            hint: '0.00',
            helper: 'Set or correct the exact balance for this source.',
          ),
          const SizedBox(height: 12),
          _buildReasonField(
            label: 'Reason',
            hint: 'Why are you adjusting this balance?',
          ),
        ];
    }
  }

  bool get _hasAdditionalDetails => true;

  Widget _buildAdditionalDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Details',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _additionalDetailsSummary,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showMoreOptions
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.mutedInk,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: _buildAdditionalDetailsFields(),
              ),
            ),
            crossFadeState: _showMoreOptions
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdditionalDetailsFields() {
    final fields = <Widget>[];

    if (_type == EntryType.lent || _type == EntryType.borrowed) {
      fields.add(
        _buildDateField(
          label: 'Transaction Date',
          value: _date,
          onTap: _pickDate,
        ),
      );
      fields.add(const SizedBox(height: 12));
      fields.add(
        _buildDateField(
          label: 'Due Date',
          value: _dueDate,
          placeholder: 'Optional',
          onTap: _pickDueDate,
          onClear:
              _dueDate == null ? null : () => setState(() => _dueDate = null),
        ),
      );
    } else {
      fields.add(
        _buildDateField(
          label: 'Date',
          value: _date,
          onTap: _pickDate,
        ),
      );
    }

    fields.add(const SizedBox(height: 12));
    fields.add(_buildNoteField());
    return fields;
  }

  String get _additionalDetailsSummary {
    final dateSummary = 'Today: ${_formatDate(_date)}';
    if (_type == EntryType.lent || _type == EntryType.borrowed) {
      final dueSummary =
          _dueDate == null ? 'No due date' : 'Due: ${_formatDate(_dueDate!)}';
      return '$dateSummary • $dueSummary • Note optional';
    }
    return '$dateSummary • Note optional';
  }

  Widget _buildReasonField({
    required String label,
    required String hint,
  }) {
    return _LabeledField(
      label: label,
      child: TextFormField(
        controller: _reasonController,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return 'Please enter a reason.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPersonField() {
    return _LabeledField(
      label: 'Person',
      child: TextFormField(
        controller: _personController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          hintText: 'Who is this related to?',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return 'Please enter a person.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProjectField() {
    return _LabeledField(
      label: 'List',
      child: TextFormField(
        controller: _projectController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          hintText: 'Bazar list, Robot parts, Team shopping...',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return 'Please enter a list name.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildItemField() {
    return _LabeledField(
      label: 'Item Name',
      child: TextFormField(
        controller: _itemController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          hintText: 'What are you recording?',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return 'Please enter an item name.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAmountField({
    required String label,
    String hint = '0.00',
    String? helper,
  }) {
    return _LabeledField(
      label: label,
      helper: helper,
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: '৳ ',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          prefixStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
        ),
        validator: (value) {
          final amount = double.tryParse((value ?? '').trim());
          if (amount == null || amount <= 0) {
            return _type == EntryType.balanceAdjustment
                ? 'Please enter a new balance.'
                : 'Please enter an amount.';
          }
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBalanceReadOnlyField() {
    final source = _selectedSource;
    final balanceText = source?.balance == null
        ? 'Balance not set'
        : formatMoney(source!.balance!);

    return _LabeledField(
      label: 'Current Balance',
      child: InputDecorator(
        decoration: const InputDecoration(
          hintText: '',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: AppColors.mutedInk,
            ),
            const SizedBox(width: 10),
            Text(
              balanceText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: source?.balance == null
                        ? AppColors.mutedInk
                        : AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceField({
    required String label,
    required String? sourceName,
    String? excludeSourceName,
    bool isDestination = false,
    String? validationMessage,
  }) {
    return _LabeledField(
      label: label,
      child: FormField<String>(
        initialValue: sourceName,
        validator: (_) {
          if (_activeSources.isEmpty) {
            return 'Please add a source first.';
          }
          if ((sourceName ?? '').trim().isEmpty) {
            return validationMessage ?? 'Please choose a source.';
          }
          if (isDestination &&
              _sourceName != null &&
              sourceName != null &&
              _sourceName == sourceName) {
            return 'From and To sources cannot be the same.';
          }
          return null;
        },
        builder: (field) {
          final source = _sourceForName(sourceName);
          final balanceText = source?.balance == null
              ? 'Balance not set'
              : formatMoney(source!.balance!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final selected = await _showSourcePicker(
                    title:
                        isDestination ? 'Choose Destination' : 'Choose Source',
                    excludeSourceName: excludeSourceName,
                  );
                  if (selected == null) return;
                  field.didChange(selected);
                  setState(() {
                    if (isDestination) {
                      _destinationSourceName = selected;
                    } else {
                      _sourceName = selected;
                      if (_destinationSourceName == selected) {
                        _destinationSourceName = _destinationOptions.isEmpty
                            ? null
                            : _destinationOptions.first;
                      }
                    }
                  });
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: _activeSources.isEmpty ? 'No sources yet' : null,
                    errorText: field.errorText,
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                  ),
                  child: source == null
                      ? Text(
                          _activeSources.isEmpty
                              ? 'Tap to add or choose a source'
                              : 'Choose a source',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.mutedInk,
                                    fontWeight: FontWeight.w600,
                                  ),
                        )
                      : Row(
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$balanceText${source.type == SourceType.other ? '' : ' • ${source.type.label}'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.mutedInk,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_activeSources.isEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            await widget.onAddSource();
                            if (mounted) setState(() {});
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Source'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return _LabeledField(
      label: 'Category',
      helper: 'Optional',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _showCategoryPicker,
        child: InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(16, 13, 12, 13),
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ),
          child: Row(
            children: [
              Icon(
                _categoryMeta(_category).icon,
                size: 18,
                color: AppColors.mutedInk,
              ),
              const SizedBox(width: 10),
              Text(
                _category,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Future<void> Function() onTap,
    String? placeholder,
    VoidCallback? onClear,
  }) {
    return _LabeledField(
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    splashRadius: 18,
                  ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.calendar_today_outlined, size: 18),
                ),
              ],
            ),
          ),
          child: Text(
            value == null ? (placeholder ?? 'Select date') : _formatDate(value),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: value == null ? AppColors.mutedInk : AppColors.ink,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return _LabeledField(
      label: 'Note',
      helper: 'Optional',
      child: TextFormField(
        controller: _noteController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Add extra context if needed',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  List<_PreviewRowData> _buildPreviewRows() {
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) return const [];

    final source = _selectedSource;
    switch (_type) {
      case EntryType.transfer:
        final destination = _sourceForName(_destinationSourceName);
        if (source == null || destination == null) return const [];
        return [
          _PreviewRowData(
            title: source.name,
            value: _previewBalanceChange(
              before: source.balance,
              after: source.balance == null ? null : (source.balance! - amount),
            ),
          ),
          _PreviewRowData(
            title: destination.name,
            value: _previewBalanceChange(
              before: destination.balance,
              after: (destination.balance ?? 0) + amount,
            ),
          ),
        ];
      case EntryType.balanceAdjustment:
        if (source == null) return const [];
        return [
          _PreviewRowData(
            title: source.name,
            value: _previewBalanceChange(
              before: source.balance,
              after: amount,
            ),
          ),
        ];
      case EntryType.income:
      case EntryType.borrowed:
        if (source == null) return const [];
        return [
          _PreviewRowData(
            title: source.name,
            value: _previewBalanceChange(
              before: source.balance,
              after: (source.balance ?? 0) + amount,
            ),
          ),
        ];
      case EntryType.expense:
      case EntryType.lent:
      case EntryType.project:
        if (source == null) return const [];
        final after = source.balance == null
            ? null
            : (source.balance! - amount).clamp(0, double.infinity).toDouble();
        return [
          _PreviewRowData(
            title: source.name,
            value: _previewBalanceChange(before: source.balance, after: after),
            tone: source.balance != null && source.balance! < amount
                ? _PreviewTone.warning
                : _PreviewTone.normal,
          ),
        ];
    }
  }

  Future<void> _showMoreTypesSheet() async {
    final selected = await showModalBottomSheet<EntryType>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'More transaction types',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a record type for loans, lists, or balance corrections.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 16),
                for (final type in _lessCommonTypes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_entryTypeIcon(type), size: 20),
                    title: Text(
                      type.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    trailing: _type == type
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(type),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _onTypeChanged(selected);
    }
  }

  Future<void> _showCategoryPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Choose Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final category in _categories)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              category.icon,
                              size: 20,
                              color: _category == category.label
                                  ? AppColors.primary
                                  : AppColors.mutedInk,
                            ),
                            title: Text(
                              category.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            trailing: _category == category.label
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(category.label),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _category = selected);
    }
  }

  Future<String?> _showSourcePicker({
    required String title,
    String? excludeSourceName,
  }) {
    final available = _activeSources.where((source) {
      if (excludeSourceName == null) return true;
      return source.name != excludeSourceName;
    }).toList();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pick a source to continue.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.mutedInk,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await widget.onAddSource();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Source'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.altSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      'No sources available yet. Add a source first.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final source = available[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.of(context).pop(source.name),
                          leading: ProviderLogo(
                            sourceName: source.name,
                            sourceType: source.type,
                            fallbackIcon: source.icon,
                            fallbackColor: source.color,
                          ),
                          title: Text(
                            source.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            source.balance == null
                                ? 'Balance not set'
                                : '${formatMoney(source.balance!)}${source.type == SourceType.other ? '' : ' • ${source.type.label}'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedInk,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          trailing: const Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: AppColors.mutedInk,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickDueDate() async {
    final initial = _dueDate ?? _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = _parsedAmount;
    if (amount == null || amount <= 0 || _sourceName == null) return;

    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        ManualEntry(
          type: _type,
          reason: _buildReason(),
          sourceName: _sourceName!,
          amount: amount,
          category: _buildCategory(),
          note: _buildNote(),
          date: _date,
          destinationSourceName:
              _type == EntryType.transfer ? _destinationSourceName : null,
        ),
      );
      if (!mounted || !saved) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved.')),
      );
      _clearFormAfterSave();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _onTypeChanged(EntryType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _showMoreOptions = false;
      if (type != EntryType.transfer) {
        _destinationSourceName = _destinationOptions.isEmpty
            ? null
            : (_destinationSourceName != null &&
                    _destinationOptions.contains(_destinationSourceName))
                ? _destinationSourceName
                : _destinationOptions.first;
      }
      if (!_needsCategory) {
        _category = 'Others';
      }
    });
  }

  void _syncSourceSelection() {
    final names = _sourceNames;
    if (names.isEmpty) {
      _sourceName = null;
      _destinationSourceName = null;
      return;
    }

    _sourceName = names.contains(_sourceName) ? _sourceName : names.first;

    final destinations = _destinationOptions;
    if (destinations.isEmpty) {
      _destinationSourceName = null;
    } else if (!destinations.contains(_destinationSourceName)) {
      _destinationSourceName = destinations.first;
    }
  }

  void _clearFormAfterSave() {
    _reasonController.clear();
    _amountController.clear();
    _noteController.clear();
    _personController.clear();
    _projectController.clear();
    _itemController.clear();
    _dueDate = null;
    _category = 'Others';
  }

  String _buildReason() {
    switch (_type) {
      case EntryType.expense:
      case EntryType.income:
      case EntryType.balanceAdjustment:
        return _reasonController.text.trim();
      case EntryType.transfer:
        final note = _noteController.text.trim();
        return note.isEmpty ? 'Source transfer' : note;
      case EntryType.lent:
      case EntryType.borrowed:
        return _personController.text.trim();
      case EntryType.project:
        return '${_projectController.text.trim()}: ${_itemController.text.trim()}';
    }
  }

  String _buildCategory() {
    switch (_type) {
      case EntryType.expense:
      case EntryType.income:
        return _category;
      case EntryType.transfer:
        return 'Transfer';
      case EntryType.lent:
        return 'Lent';
      case EntryType.borrowed:
        return 'Borrowed';
      case EntryType.project:
        return 'List';
      case EntryType.balanceAdjustment:
        return 'Balance';
    }
  }

  String _buildNote() {
    final note = _noteController.text.trim();
    if ((_type == EntryType.lent || _type == EntryType.borrowed) &&
        _dueDate != null) {
      final dueText = 'Due: ${_formatDate(_dueDate!)}';
      return note.isEmpty ? dueText : '$note\n$dueText';
    }
    return note;
  }

  List<String> get _destinationOptions {
    final from = _sourceName;
    return _sourceNames.where((name) => name != from).toList();
  }

  MoneySource? get _selectedSource => _sourceForName(_sourceName);

  MoneySource? _sourceForName(String? name) {
    if (name == null) return null;
    for (final source in _activeSources) {
      if (source.name == name) return source;
    }
    return null;
  }

  _CategoryOption _categoryMeta(String label) {
    return _categories.firstWhere(
      (item) => item.label == label,
      orElse: () => _categories.last,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _previewBalanceChange({
    required double? before,
    required double? after,
  }) {
    final beforeText = before == null ? 'Balance not set' : formatMoney(before);
    final afterText = after == null ? 'Balance not set' : formatMoney(after);
    return '$beforeText -> $afterText';
  }

  IconData _entryTypeIcon(EntryType type) {
    return switch (type) {
      EntryType.expense => Icons.arrow_outward_rounded,
      EntryType.income => Icons.arrow_downward_rounded,
      EntryType.transfer => Icons.swap_horiz_rounded,
      EntryType.lent => Icons.call_made_rounded,
      EntryType.borrowed => Icons.call_received_rounded,
      EntryType.project => Icons.list_alt_rounded,
      EntryType.balanceAdjustment => Icons.tune_rounded,
    };
  }
}

class _EntryTypeSelector extends StatelessWidget {
  const _EntryTypeSelector({
    required this.selected,
    required this.onSelected,
    required this.onOpenMore,
  });

  final EntryType selected;
  final ValueChanged<EntryType> onSelected;
  final Future<void> Function() onOpenMore;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in _AddTransactionTabState._commonTypes)
          ChoiceChip(
            selected: selected == type,
            label: Text(type.label),
            onSelected: (_) => onSelected(type),
          ),
        ActionChip(
          label: Text(
            _AddTransactionTabState._lessCommonTypes.contains(selected)
                ? 'More: ${selected.label}'
                : 'More',
          ),
          avatar: const Icon(
            Icons.apps_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          side: const BorderSide(color: AppColors.line),
          backgroundColor: AppColors.card,
          onPressed: onOpenMore,
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (helper != null) ...[
              const SizedBox(width: 8),
              Text(
                helper!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _AdjustmentInfoCard extends StatelessWidget {
  const _AdjustmentInfoCard({required this.source});

  final MoneySource? source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              source == null
                  ? 'Use this to set or correct a source balance.'
                  : 'This will update ${source!.name} to the exact balance you enter.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.rows});

  final List<_PreviewRowData> rows;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated balance after save.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: row.tone == _PreviewTone.warning
                              ? AppColors.warning
                              : AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            if (row != rows.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _PreviewRowData {
  const _PreviewRowData({
    required this.title,
    required this.value,
    this.tone = _PreviewTone.normal,
  });

  final String title;
  final String value;
  final _PreviewTone tone;
}

enum _PreviewTone { normal, warning }
