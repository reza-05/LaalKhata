import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/ledger_presentation_models.dart';
import 'provider_logo.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.activities,
    required this.sources,
  });

  final List<ActivityItem> activities;
  final List<MoneySource> sources;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _searchQuery = '';
  String _selectedType = 'All'; // 'All', 'Expense', 'Income', 'Transfer', 'Adjustment'
  String _selectedSource = 'All'; // 'All' or specific source name

  final List<String> _types = ['All', 'Expense', 'Income', 'Transfer', 'Adjustment'];

  @override
  Widget build(BuildContext context) {
    // 1. Filter activities
    final filtered = widget.activities.where((activity) {
      // Search text match
      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final nameMatch = activity.name.toLowerCase().contains(query);
        final categoryMatch = activity.category.toLowerCase().contains(query);
        final sourceMatch = activity.source.toLowerCase().contains(query);
        final amountMatch = activity.amount.toString().contains(query);
        if (!nameMatch && !categoryMatch && !sourceMatch && !amountMatch) {
          return false;
        }
      }

      // Type filter match
      if (_selectedType != 'All') {
        final typeLower = activity.type.toLowerCase();
        if (_selectedType == 'Expense') {
          if (!const {'expense', 'debit', 'lent', 'project'}.contains(typeLower)) {
            return false;
          }
        } else if (_selectedType == 'Income') {
          if (!const {'income', 'credit', 'borrowed'}.contains(typeLower)) {
            return false;
          }
        } else if (_selectedType == 'Transfer') {
          if (typeLower != 'transfer' && typeLower != 'coverage') {
            return false;
          }
        } else if (_selectedType == 'Adjustment') {
          if (typeLower != 'balanceadjustment' && typeLower != 'openingbalance') {
            return false;
          }
        }
      }

      // Source filter match
      if (_selectedSource != 'All') {
        // match by name contains (case insensitive)
        final sourceLower = activity.source.toLowerCase();
        final filterLower = _selectedSource.toLowerCase();
        if (!sourceLower.contains(filterLower) && !filterLower.contains(sourceLower)) {
          return false;
        }
      }

      return true;
    }).toList();

    // 2. Group by date
    final Map<String, List<ActivityItem>> grouped = {};
    for (final activity in filtered) {
      final header = _getGroupHeader(activity.occurredAt);
      grouped.update(header, (list) => list..add(activity), ifAbsent: () => [activity]);
    }

    final sortedKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.altSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedInk),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Type Filter Chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : AppColors.mutedInk,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.24) : AppColors.line,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),

            // Source Filter Chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All Sources'),
                      selected: _selectedSource == 'All',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedSource = 'All');
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedSource == 'All' ? AppColors.primary : AppColors.mutedInk,
                      ),
                      side: BorderSide(
                        color: _selectedSource == 'All' ? AppColors.primary.withValues(alpha: 0.24) : AppColors.line,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ...widget.sources.map((source) {
                    final isSelected = _selectedSource == source.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(source.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSource = source.name);
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.mutedInk,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.24) : AppColors.line,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Transactions List Grouped by Date
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.mutedInk,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your filters or search query.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.mutedInk,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final dateHeader = sortedKeys[index];
                        final list = grouped[dateHeader]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                              child: Text(
                                dateHeader,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.mutedInk,
                                    ),
                              ),
                            ),
                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < list.length; i++) ...[
                                      _buildActivityRow(context, list[i]),
                                      if (i < list.length - 1) const Divider(height: 16),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, ActivityItem activity) {
    final isExpense = isExpenseActivity(activity);
    final isIncome = isIncomeActivity(activity);
    final isTransfer = activity.type == 'transfer' || activity.type == 'coverage';
    final isAdjustment = activity.type == 'balanceAdjustment' || activity.type == 'openingBalance';

    Color amountColor = AppColors.mutedInk;
    String sign = '';
    if (isExpense) {
      amountColor = AppColors.danger;
      sign = '-';
    } else if (isIncome) {
      amountColor = AppColors.positive;
      sign = '+';
    } else if (isAdjustment) {
      amountColor = activity.amount >= 0 ? AppColors.positive : AppColors.danger;
      sign = activity.amount >= 0 ? '+' : '-';
    }

    // Local time representation
    final localTime = activity.occurredAt.toLocal();
    final timeStr = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';

    // Find source details
    final sourceObj = widget.sources.cast<MoneySource?>().firstWhere(
          (s) => s != null && s.name.toLowerCase() == activity.source.toLowerCase(),
          orElse: () => null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProviderLogo(
            sourceName: activity.source,
            sourceType: sourceObj?.type ?? SourceType.other,
            fallbackIcon: sourceObj?.icon ?? activity.icon,
            fallbackColor: sourceObj?.color ?? AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.source} • $timeStr • ${activity.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isTransfer
                ? formatMoney(activity.amount)
                : activity.amount == 0
                    ? 'Recorded'
                    : '$sign${formatMoney(activity.amount.abs())}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isTransfer || activity.amount == 0 ? AppColors.mutedInk : amountColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }

  String _getGroupHeader(DateTime occurredAt) {
    final localTime = occurredAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(localTime.year, localTime.month, localTime.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = months[localTime.month - 1];
      return '${localTime.day} $monthStr ${localTime.year}';
    }
  }
}
