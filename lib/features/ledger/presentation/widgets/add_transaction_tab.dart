import 'package:flutter/material.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_layout_widgets.dart';

class AddTransactionTab extends StatefulWidget {
  const AddTransactionTab({
    super.key,
    required this.sources,
    required this.onSave,
  });

  final List<MoneySource> sources;
  final Future<bool> Function(ManualEntry entry) onSave;

  @override
  State<AddTransactionTab> createState() => _AddTransactionTabState();
}

class _AddTransactionTabState extends State<AddTransactionTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  EntryType _type = EntryType.expense;
  String _sourceName = 'Cash';
  String? _destinationSourceName;
  String _category = 'Others';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceNames = widget.sources.map((source) => source.name).toList();
    if (!sourceNames.contains(_sourceName) && sourceNames.isNotEmpty) {
      _sourceName = sourceNames.first;
    }
    final destinationOptions =
        sourceNames.where((name) => name != _sourceName).toList();
    if (!destinationOptions.contains(_destinationSourceName)) {
      _destinationSourceName =
          destinationOptions.isEmpty ? null : destinationOptions.first;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const PageTitle(
          title: 'Add',
          subtitle: 'Record income, expense, transfer, dues, or adjustments',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntryTypeSelector(
                    selected: _type,
                    onSelected: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name / Reason',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Name or reason is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue:
                        sourceNames.contains(_sourceName) ? _sourceName : null,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: sourceNames
                        .map(
                          (source) => DropdownMenuItem(
                            value: source,
                            child: Text(source),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _sourceName = value;
                        if (_destinationSourceName == value) {
                          _destinationSourceName = sourceNames.firstWhere(
                            (name) => name != value,
                            orElse: () => value,
                          );
                        }
                      });
                    },
                  ),
                  if (_type == EntryType.transfer) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          destinationOptions.contains(_destinationSourceName)
                              ? _destinationSourceName
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Transfer to',
                        prefixIcon: Icon(Icons.call_received_rounded),
                      ),
                      items: destinationOptions
                          .map(
                            (source) => DropdownMenuItem(
                              value: source,
                              child: Text(source),
                            ),
                          )
                          .toList(),
                      validator: (value) {
                        if (_type == EntryType.transfer && value == null) {
                          return 'Select a destination source.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() => _destinationSourceName = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: '৳ ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          'Others',
                          'Food',
                          'Transport',
                          'Study',
                          'Hall',
                          'Treat/Party',
                        ]
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      DateField(
                        date: _date,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Transaction'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());

    final saved = await widget.onSave(
      ManualEntry(
        type: _type,
        reason: _nameController.text.trim(),
        sourceName: _sourceName,
        amount: amount,
        category: _category,
        note: _noteController.text.trim(),
        date: _date,
        destinationSourceName:
            _type == EntryType.transfer ? _destinationSourceName : null,
      ),
    );
    if (!mounted || !saved) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved.')),
    );

    _nameController.clear();
    _amountController.clear();
    _noteController.clear();
  }
}

class EntryTypeSelector extends StatelessWidget {
  const EntryTypeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final EntryType selected;
  final ValueChanged<EntryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in EntryType.values)
          ChoiceChip(
            selected: selected == value,
            label: Text(value.label),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
