import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../ledger/presentation/models/ledger_presentation_models.dart';
import '../../../ledger/presentation/widgets/ledger_layout_widgets.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({
    super.key,
    required this.initialLists,
    required this.onCreateList,
    required this.onRenameList,
    required this.onDeleteList,
    required this.onAddItem,
    required this.onDeleteItem,
  });

  final List<LedgerList> initialLists;
  final Future<LedgerList?> Function(String title) onCreateList;
  final Future<void> Function(LedgerList list, String title) onRenameList;
  final Future<void> Function(LedgerList list) onDeleteList;
  final Future<LedgerListItem?> Function(
    LedgerList list,
    String title,
    double amount,
  ) onAddItem;
  final Future<void> Function(LedgerList list, LedgerListItem item)
      onDeleteItem;

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  late final List<LedgerList> _lists;

  @override
  void initState() {
    super.initState();
    _lists = [...widget.initialLists];
    _sortLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Lists',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PageTitle(
                  title: 'Lists',
                  subtitle:
                      'Plan purchases and item totals without affecting balances yet.',
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _createList,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New List'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.subtleShadow.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lists stay in planning mode until we add checkout later. Your source balances remain unchanged.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_lists.isEmpty)
            _ListsEmptyState(onCreateList: _createList)
          else
            ..._lists.map(
              (list) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ListOverviewCard(
                  list: list,
                  onTap: () => _openList(list),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createList() async {
    final title = await _showListTitleSheet();
    if (!mounted || title == null) return;
    final created = await widget.onCreateList(title);
    if (!mounted || created == null) return;
    setState(() {
      _lists.insert(0, created);
      _sortLists();
    });
    _openList(created);
  }

  Future<void> _openList(LedgerList list) async {
    final parentNavigator = Navigator.of(context);
    await parentNavigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ListDetailPage(
          list: list,
          onRename: (title) async {
            await widget.onRenameList(list, title);
            if (!mounted) return;
            setState(_sortLists);
          },
          onDelete: () async {
            await widget.onDeleteList(list);
            if (!mounted) return;
            setState(() {
              _lists.removeWhere((entry) => entry.id == list.id);
            });
            parentNavigator.pop();
          },
          onAddItem: (title, amount) async {
            final item = await widget.onAddItem(list, title, amount);
            if (!mounted) return null;
            setState(_sortLists);
            return item;
          },
          onDeleteItem: (item) async {
            await widget.onDeleteItem(list, item);
            if (!mounted) return;
            setState(_sortLists);
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(_sortLists);
  }

  void _sortLists() {
    _lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<String?> _showListTitleSheet({String? initialValue}) {
    final controller = TextEditingController(text: initialValue ?? '');
    String? errorText;
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initialValue == null ? 'Create New List' : 'Rename List',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use a clear title like Bazar, Groceries, or Robot Parts.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'List title',
                      hintText: 'Groceries for this week',
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setModalState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          setModalState(() {
                            errorText = 'Please enter a list title.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(value);
                      },
                      child:
                          Text(initialValue == null ? 'Create List' : 'Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ListDetailPage extends StatefulWidget {
  const ListDetailPage({
    super.key,
    required this.list,
    required this.onRename,
    required this.onDelete,
    required this.onAddItem,
    required this.onDeleteItem,
  });

  final LedgerList list;
  final Future<void> Function(String title) onRename;
  final Future<void> Function() onDelete;
  final Future<LedgerListItem?> Function(String title, double amount) onAddItem;
  final Future<void> Function(LedgerListItem item) onDeleteItem;

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  late LedgerList _list;

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItems(_list.items);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _list.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Rename',
            onPressed: _renameList,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete list',
            onPressed: _deleteList,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          _ListHeroCard(list: _list),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Items',
            actionLabel: _list.items.isEmpty ? null : 'Add',
            onAction: _list.items.isEmpty ? null : _addItem,
          ),
          const SizedBox(height: 10),
          if (_list.items.isEmpty)
            _ListItemsEmptyState(onAddItem: _addItem)
          else
            ...groupedItems.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ListGroupCard(
                  title: entry.key,
                  items: entry.value,
                  onDeleteItem: (item) async {
                    await widget.onDeleteItem(item);
                    if (!mounted) return;
                    setState(() {
                      _list = _list.copyWith(
                        updatedAt: DateTime.now().toUtc(),
                        items: _list.items
                            .where((entry) => entry.id != item.id)
                            .toList(),
                      );
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final payload = await _showAddItemSheet(context);
    if (!mounted || payload == null) return;
    final item = await widget.onAddItem(payload.title, payload.amount);
    if (!mounted || item == null) return;
    setState(() {
      _list = _list.copyWith(
        updatedAt: item.createdAt,
        items: [item, ..._list.items],
      );
    });
  }

  Future<void> _renameList() async {
    final title = await _showListRenameSheet(context, _list.title);
    if (!mounted || title == null) return;
    await widget.onRename(title);
    if (!mounted) return;
    setState(() {
      _list = _list.copyWith(
        title: title.trim(),
        updatedAt: DateTime.now().toUtc(),
      );
    });
  }

  Future<void> _deleteList() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Delete "${_list.title}" and all of its planned items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    await widget.onDelete();
  }
}

class _ListOverviewCard extends StatelessWidget {
  const _ListOverviewCard({
    required this.list,
    required this.onTap,
  });

  final LedgerList list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.subtleShadow.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${list.itemCount} item${list.itemCount == 1 ? '' : 's'} • Updated ${_formatListMetaDate(list.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(list.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedInk,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListHeroCard extends StatelessWidget {
  const _ListHeroCard({required this.list});

  final LedgerList list;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.subtleShadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planned Total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(list.totalAmount),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.altSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ListMetaStat(
                    label: 'Items',
                    value: '${list.itemCount}',
                  ),
                ),
                Container(width: 1, height: 34, color: AppColors.line),
                Expanded(
                  child: _ListMetaStat(
                    label: 'Created',
                    value: _formatCompactDate(list.createdAt),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListMetaStat extends StatelessWidget {
  const _ListMetaStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ListGroupCard extends StatelessWidget {
  const _ListGroupCard({
    required this.title,
    required this.items,
    required this.onDeleteItem,
  });

  final String title;
  final List<LedgerListItem> items;
  final ValueChanged<LedgerListItem> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
              child: _ListItemRow(
                item: item,
                onDelete: () => onDeleteItem(item),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ListItemRow extends StatelessWidget {
  const _ListItemRow({
    required this.item,
    required this.onDelete,
  });

  final LedgerListItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatMoney(item.amount),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: 6),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.mutedInk,
          ),
        ),
      ],
    );
  }
}

class _ListsEmptyState extends StatelessWidget {
  const _ListsEmptyState({required this.onCreateList});

  final VoidCallback onCreateList;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.playlist_add_check_circle_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No lists yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a list for groceries, robot parts, shopping, or anything you want to price before checkout.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateList,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First List'),
          ),
        ],
      ),
    );
  }
}

class _ListItemsEmptyState extends StatelessWidget {
  const _ListItemsEmptyState({required this.onAddItem});

  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.list_alt_rounded,
            size: 36,
            color: AppColors.mutedInk,
          ),
          const SizedBox(height: 12),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first planned item with a title and price.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}

class _NewItemPayload {
  const _NewItemPayload({
    required this.title,
    required this.amount,
  });

  final String title;
  final double amount;
}

Future<_NewItemPayload?> _showAddItemSheet(BuildContext context) {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  String? titleError;
  String? amountError;

  return showModalBottomSheet<_NewItemPayload>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Item',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a title and price. Planned totals update instantly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Item title',
                    hintText: 'Milk, Rice, Servo Motor',
                    errorText: titleError,
                  ),
                  onChanged: (_) {
                    if (titleError != null) {
                      setModalState(() => titleError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '৳ ',
                    hintText: '0.00',
                    errorText: amountError,
                  ),
                  onChanged: (_) {
                    if (amountError != null) {
                      setModalState(() => amountError = null);
                    }
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final amount =
                          double.tryParse(amountController.text.trim());

                      if (title.isEmpty) {
                        setModalState(() {
                          titleError = 'Please enter an item title.';
                        });
                        return;
                      }
                      if (amount == null || amount <= 0) {
                        setModalState(() {
                          amountError = 'Please enter a valid price.';
                        });
                        return;
                      }

                      Navigator.of(context).pop(
                        _NewItemPayload(title: title, amount: amount),
                      );
                    },
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<String?> _showListRenameSheet(
    BuildContext context, String initialValue) {
  final controller = TextEditingController(text: initialValue);
  String? errorText;

  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rename List',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep the title short and clear so it is easy to scan later.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'List title',
                    hintText: 'Groceries for this week',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setModalState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isEmpty) {
                        setModalState(() {
                          errorText = 'Please enter a list title.';
                        });
                        return;
                      }
                      Navigator.of(context).pop(value);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Map<String, List<LedgerListItem>> _groupItems(List<LedgerListItem> items) {
  final grouped = <String, List<LedgerListItem>>{};
  for (final item in items) {
    final key = formatActivityDate(item.createdAt);
    grouped.putIfAbsent(key, () => <LedgerListItem>[]).add(item);
  }
  return grouped;
}

String _formatListMetaDate(DateTime value) {
  final formatted = formatActivityDate(value);
  if (formatted == 'Today' || formatted == 'Yesterday') return formatted;
  return formatted;
}

String _formatCompactDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]}';
}
