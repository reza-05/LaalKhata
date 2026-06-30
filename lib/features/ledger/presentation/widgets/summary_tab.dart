import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/domain/source_identity.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/home_tab.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_layout_widgets.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';

class SummaryTab extends StatefulWidget {
  const SummaryTab({
    super.key,
    required this.sources,
    required this.activities,
    required this.monthlyTargets,
    required this.onSaveMonthlyTarget,
    required this.onViewActivities,
  });

  final List<MoneySource> sources;
  final List<ActivityItem> activities;
  final Map<String, double> monthlyTargets;
  final Future<void> Function(String monthKey, double amount)
      onSaveMonthlyTarget;
  final VoidCallback onViewActivities;

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  SummaryFilter _selectedFilter = SummaryFilter.thisMonth;
  DateTimeRange? _customRange;
  bool _targetBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final range = _activeRange(now);
    final filteredActivities = _activitiesForRange(range);
    final expenseActivities =
        filteredActivities.where(_countsForDashboardExpense).toList();
    final incomeActivities =
        filteredActivities.where(_countsForDashboardIncome).toList();
    final summaryExpense =
        expenseActivities.fold(0.0, (sum, item) => sum + item.amount.abs());
    final summaryIncome =
        incomeActivities.fold(0.0, (sum, item) => sum + item.amount.abs());
    final targetMonth = _targetMonthForRange(range);
    final targetMonthKey = _monthKey(targetMonth);
    final targetAmount = widget.monthlyTargets[targetMonthKey];
    final targetExpense = _strictMonthlyExpense(targetMonth);
    final targetProgress =
        targetAmount == null || targetAmount <= 0 ? 0.0 : targetExpense / targetAmount;
    final recentActivities = filteredActivities.take(7).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        PageTitle(
          title: 'Summary',
          subtitle: _filterSubtitle(range),
          trailing: _FilterTriggerChip(
            label: _selectedFilter.label,
            onTap: _showFilterSheet,
          ),
        ),
        const SizedBox(height: 18),
        _MetricGrid(
          items: [
            _MetricCardData(
              title: 'Expense',
              value: formatMoney(summaryExpense),
              tone: AppColors.danger,
              subtitle: 'Spent',
              icon: Icons.south_west_rounded,
            ),
            _MetricCardData(
              title: 'Income',
              value: formatMoney(summaryIncome),
              tone: AppColors.positive,
              subtitle: 'Received',
              icon: Icons.north_east_rounded,
            ),
            _MetricCardData(
              title: 'Net',
              value: formatMoney(summaryIncome - summaryExpense),
              tone: summaryIncome - summaryExpense >= 0
                  ? AppColors.positive
                  : AppColors.danger,
              subtitle: 'Income - Expense',
              icon: Icons.account_balance_wallet_rounded,
            ),
            _MetricCardData(
              title: 'Target',
              value: targetAmount == null
                  ? 'Not Set'
                  : '${(targetProgress * 100).clamp(0, 999).round()}%',
              tone: _targetTone(targetProgress),
              subtitle: targetAmount == null
                  ? 'Set this month\'s cap'
                  : _targetMessage(targetProgress),
              icon: Icons.track_changes_rounded,
            ),
          ],
        ),
        if (targetAmount == null) ...[
          if (!_targetBannerDismissed) ...[
            const SizedBox(height: 16),
            _NoTargetBanner(
              onSetTarget: () => _showTargetDialog(targetMonthKey, targetAmount),
              onDismiss: () => setState(() => _targetBannerDismissed = true),
            ),
          ],
        ] else ...[
          const SizedBox(height: 16),
          _CompactTargetProgressBanner(
            monthLabel: _monthLabel(targetMonth),
            targetAmount: targetAmount,
            spent: targetExpense,
            progress: targetProgress,
            onEditTarget: () => _showTargetDialog(targetMonthKey, targetAmount),
          ),
        ],
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 760;
            final chartCards = [
              _ChartCard(
                title: 'Category Distribution',
                subtitle: 'See where your spending is going.',
                child: _CategoryDonutSection(
                  items: _categoryBreakdown(expenseActivities),
                ),
              ),
              _ChartCard(
                title: 'Daily Spending',
                subtitle: 'Spot recent changes quickly.',
                child: _DailySpendingSection(
                  bars: _dailyBars(range, filteredActivities),
                ),
              ),
            ];

            if (stacked) {
              return Column(
                children: [
                  chartCards[0],
                  const SizedBox(height: 16),
                  chartCards[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: chartCards[0]),
                const SizedBox(width: 16),
                Expanded(child: chartCards[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final categoryItems = _categoryBreakdown(expenseActivities);
            final sourceItems = _sourceBreakdown(expenseActivities);
            final stacked = constraints.maxWidth < 760;
            final cards = [
              _BreakdownInsightCard(
                title: 'Category Breakdown',
                subtitle: 'Top expense categories in this range.',
                emptyText: 'No expense categories to show yet.',
                children: categoryItems
                    .map(
                      (item) => _BreakdownRow(
                        label: item.label,
                        value: item.value,
                        share: item.share,
                        color: item.color,
                        icon: _categoryMeta(item.label).icon,
                      ),
                    )
                    .toList(),
              ),
              _BreakdownInsightCard(
                title: 'Source Breakdown',
                subtitle: 'Which sources handled most spending.',
                emptyText: 'Source distribution will appear after expenses.',
                children: sourceItems
                    .map(
                      (item) => _SourceBreakdownRow(
                        item: item,
                        source: widget.sources.firstWhere(
                          (source) =>
                              sourceIdentityKey(source.name) ==
                              sourceIdentityKey(item.label),
                          orElse: () => MoneySource(
                            name: item.label,
                            type: SourceType.other,
                            balance: null,
                            color: AppColors.primary,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ];

            if (stacked) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 16),
                  cards[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Recent Activity',
          actionLabel: 'View All',
          onAction: widget.onViewActivities,
        ),
        const SizedBox(height: 10),
        RecentActivityCard(
          activities: recentActivities,
          maxItems: recentActivities.length,
        ),
      ],
    );
  }

  Future<void> _showFilterSheet() async {
    final selected = await showModalBottomSheet<SummaryFilter>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selected: _selectedFilter,
        onCustomRangeTap: _pickCustomRange,
      ),
    );

    if (!mounted || selected == null) return;
    if (selected == SummaryFilter.custom) {
      await _pickCustomRange();
      return;
    }

    setState(() {
      _selectedFilter = selected;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _customRange = picked;
      _selectedFilter = SummaryFilter.custom;
    });
  }

  Future<void> _showTargetDialog(
    String monthKey,
    double? currentTarget,
  ) async {
    final target = await showDialog<double>(
      context: context,
      builder: (context) => _TargetDialog(
        monthLabel: _monthLabel(_monthKeyToDate(monthKey)),
        initialValue: currentTarget,
      ),
    );

    if (!mounted || target == null) return;
    await widget.onSaveMonthlyTarget(monthKey, target);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monthly target updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }



  DateTimeRange _activeRange(DateTime now) {
    switch (_selectedFilter) {
      case SummaryFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case SummaryFilter.thisWeek:
        final weekdayOffset = now.weekday - DateTime.monday;
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekdayOffset));
        return DateTimeRange(start: start, end: now);
      case SummaryFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case SummaryFilter.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case SummaryFilter.custom:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            );
    }
  }

  List<ActivityItem> _activitiesForRange(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    final items = widget.activities.where((activity) {
      final time = activity.occurredAt;
      return !time.isBefore(start) && !time.isAfter(end);
    }).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return items;
  }

  DateTime _targetMonthForRange(DateTimeRange range) {
    return DateTime(range.end.year, range.end.month, 1);
  }

  double _strictMonthlyExpense(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return widget.activities
        .where((activity) =>
            activity.type == 'expense' &&
            !activity.occurredAt.isBefore(start) &&
            !activity.occurredAt.isAfter(end))
        .fold(0.0, (sum, activity) => sum + activity.amount.abs());
  }

  List<_BreakdownEntry> _categoryBreakdown(List<ActivityItem> activities) {
    final totals = <String, double>{};
    for (final activity in activities) {
      final label = _categoryMeta(activity.category).label;
      totals.update(
        label,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }
    final total = totals.values.fold(0.0, (sum, value) => sum + value);
    final entries = totals.entries
        .map(
          (entry) => _BreakdownEntry(
            label: entry.key,
            value: entry.value,
            share: total == 0 ? 0 : entry.value / total,
            color: _categoryMeta(entry.key).color,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<_BreakdownEntry> _sourceBreakdown(List<ActivityItem> activities) {
    final totals = <String, double>{};
    for (final activity in activities) {
      totals.update(
        activity.source,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }
    final total = totals.values.fold(0.0, (sum, value) => sum + value);
    final entries = totals.entries
        .map(
          (entry) => _BreakdownEntry(
            label: entry.key,
            value: entry.value,
            share: total == 0 ? 0 : entry.value / total,
            color: _sourceColor(entry.key),
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<_DailySpendBar> _dailyBars(
    DateTimeRange range,
    List<ActivityItem> filteredActivities,
  ) {
    final totals = <DateTime, double>{};
    for (final activity in filteredActivities.where(_countsForDashboardExpense)) {
      final day = DateTime(
        activity.occurredAt.year,
        activity.occurredAt.month,
        activity.occurredAt.day,
      );
      totals.update(
        day,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }

    final dayCount = math.min(
      7,
      range.end.difference(range.start).inDays.abs() + 1,
    );
    final startDay = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    ).subtract(Duration(days: dayCount - 1));

    return List.generate(dayCount, (index) {
      final day = startDay.add(Duration(days: index));
      return _DailySpendBar(
        label: _weekdayLabel(day),
        amount: totals[day] ?? 0,
      );
    });
  }

  String _filterSubtitle(DateTimeRange range) {
    return '${_selectedFilter.title} • ${_friendlyDate(range.start)} - ${_friendlyDate(range.end)}';
  }

  String _friendlyDate(DateTime value) {
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

  String _weekdayLabel(DateTime value) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[value.weekday - 1];
  }

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  DateTime _monthKeyToDate(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return DateTime.now();
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateTime(year, month, 1);
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  Color _sourceColor(String sourceName) {
    final source = widget.sources.cast<MoneySource?>().firstWhere(
          (item) =>
              item != null &&
              sourceIdentityKey(item.name) == sourceIdentityKey(sourceName),
          orElse: () => null,
        );
    return source?.color ?? AppColors.primary;
  }
}

enum SummaryFilter {
  today('Today', 'Today'),
  thisWeek('This Week', 'This Week'),
  thisMonth('This Month', 'This Month'),
  lastMonth('Last Month', 'Last Month'),
  custom('Custom Range', 'Custom');

  const SummaryFilter(this.title, this.label);

  final String title;
  final String label;
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tone;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.items,
  });

  final List<_MetricCardData> items;

  @override
  Widget build(BuildContext context) {
    if (items.length < 4) return const SizedBox.shrink();
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MetricCard(item: items[0])),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(item: items[1])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MetricCard(item: items[2])),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(item: items[3])),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.item,
  });

  final _MetricCardData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.tone.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.tone, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontSize: 12,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTargetBanner extends StatelessWidget {
  const _NoTargetBanner({
    required this.onSetTarget,
    required this.onDismiss,
  });

  final VoidCallback onSetTarget;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.expense,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Monthly target is not set',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                Text(
                  'Set a spending cap to track your progress.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onSetTarget,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: const BorderSide(color: AppColors.expense),
              foregroundColor: AppColors.expense,
            ),
            child: const Text('Set Target', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.mutedInk,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _CompactTargetProgressBanner extends StatelessWidget {
  const _CompactTargetProgressBanner({
    required this.monthLabel,
    required this.targetAmount,
    required this.spent,
    required this.progress,
    required this.onEditTarget,
  });

  final String monthLabel;
  final double targetAmount;
  final double spent;
  final double progress;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final double pct = progress * 100;
    Color statusColor;
    String statusLabel = '';
    IconData statusIcon;

    if (progress >= 1.0) {
      statusColor = const Color(0xFF991B1B); // Dark Red
      statusLabel = 'Target Exceeded';
      statusIcon = Icons.cancel_outlined;
    } else if (pct >= 90) {
      statusColor = AppColors.danger; // Red
      statusLabel = 'Almost Reached';
      statusIcon = Icons.error_outline_rounded;
    } else if (pct >= 70) {
      statusColor = const Color(0xFFD97706); // Amber
      statusLabel = 'Approaching Limit';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppColors.positive; // Green
      statusLabel = 'Within Target';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line), // Uniform outer border to avoid BorderRadius crash
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium colored left accent strip
              Container(
                width: 5,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Monthly Target ($monthLabel)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.mutedInk,
                                  ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onEditTarget,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Edit',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Used amount info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Used',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.mutedInk,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formatMoney(spent),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                        fontSize: 18,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'of ${formatMoney(targetAmount)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.mutedInk,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Remaining amount info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remaining',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.mutedInk,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formatMoney(math.max(0.0, targetAmount - spent)),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                        fontSize: 18,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  spent > targetAmount ? 'Exceeded Limit' : 'Under target cap',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.mutedInk,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Percentage and Status info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(progress * 100).clamp(0, 999).round()}%',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      fontSize: 22,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                        builder: (context, animValue, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 8, // 8px thick progress bar
                              value: animValue,
                              color: statusColor,
                              backgroundColor: AppColors.altSurface,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _CategoryDonutSection extends StatelessWidget {
  const _CategoryDonutSection({
    required this.items,
  });

  final List<_BreakdownEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyChartState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No category data available yet.',
      );
    }

    final topItems = items.take(5).toList();
    return Row(
      children: [
        SizedBox(
          width: 136,
          height: 136,
          child: CustomPaint(
            painter: _DonutChartPainter(items: topItems),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Top',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    topItems.first.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (final item in topItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${(item.share * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedInk,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailySpendingSection extends StatelessWidget {
  const _DailySpendingSection({
    required this.bars,
  });

  final List<_DailySpendBar> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.every((bar) => bar.amount <= 0)) {
      return const _EmptyChartState(
        icon: Icons.insights_outlined,
        message: 'Daily spending will appear after expenses are added.',
      );
    }

    final maxValue = bars.fold<double>(
      0,
      (maxAmount, bar) => math.max(maxAmount, bar.amount),
    );
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final bar in bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      bar.amount <= 0 ? '—' : formatMoney(bar.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 112,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        width: 28,
                        height: maxValue == 0 ? 0 : (bar.amount / maxValue) * 112,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accent,
                              AppColors.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bar.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
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

class _BreakdownInsightCard extends StatelessWidget {
  const _BreakdownInsightCard({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
            const SizedBox(height: 16),
            if (children.isEmpty)
              Text(
                emptyText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                    ),
              )
            else
              ...children.expand(
                (child) => [
                  child,
                  if (child != children.last) const SizedBox(height: 14),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.share,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final double share;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    '${(share * 100).toStringAsFixed(0)}% of spending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(value),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: share.clamp(0, 1),
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.altSurface,
          ),
        ),
      ],
    );
  }
}

class _SourceBreakdownRow extends StatelessWidget {
  const _SourceBreakdownRow({
    required this.item,
    required this.source,
  });

  final _BreakdownEntry item;
  final MoneySource source;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    '${source.type.label} • ${(item.share * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(item.value),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.share.clamp(0, 1),
            minHeight: 8,
            color: item.color,
            backgroundColor: AppColors.altSurface,
          ),
        ),
      ],
    );
  }
}

class _FilterTriggerChip extends StatelessWidget {
  const _FilterTriggerChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selected,
    required this.onCustomRangeTap,
  });

  final SummaryFilter selected;
  final Future<void> Function() onCustomRangeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Range',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Switch between quick financial views.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
            const SizedBox(height: 18),
            for (final filter in SummaryFilter.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).pop(filter);
                  },
                  child: Ink(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected == filter
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.altSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected == filter
                            ? AppColors.primary.withValues(alpha: 0.24)
                            : AppColors.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected == filter
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected == filter
                              ? AppColors.primary
                              : AppColors.mutedInk,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            filter.title,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ),
                        if (filter == SummaryFilter.custom)
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await onCustomRangeTap();
                            },
                            child: const Text('Pick'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({
    required this.monthLabel,
    required this.initialValue,
  });

  final String monthLabel;
  final double? initialValue;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue == null || widget.initialValue == 0
        ? ''
        : widget.initialValue!.round().toString(),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly Target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.monthLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Target amount',
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0) {
      setState(() => _error = 'Please enter a valid target amount.');
      return;
    }
    Navigator.of(context).pop(value);
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.mutedInk, size: 34),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.items,
  });

  final List<_BreakdownEntry> items;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = 16.0;
    final total = items.fold(0.0, (sum, item) => sum + item.value);
    final basePaint = Paint()
      ..color = AppColors.altSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      basePaint,
    );

    var start = -math.pi / 2;
    for (final item in items) {
      final sweep = total == 0 ? 0.0 : (item.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        items.length == 1 ? sweep : math.max(sweep - 0.04, 0.0),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}


class _BreakdownEntry {
  const _BreakdownEntry({
    required this.label,
    required this.value,
    required this.share,
    required this.color,
  });

  final String label;
  final double value;
  final double share;
  final Color color;
}

class _DailySpendBar {
  const _DailySpendBar({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

_CategoryMeta _categoryMeta(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.contains('food')) {
    return const _CategoryMeta(
      label: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEF4444),
    );
  }
  if (normalized.contains('transport')) {
    return const _CategoryMeta(
      label: 'Transport',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFF3B82F6),
    );
  }
  if (normalized.contains('education')) {
    return const _CategoryMeta(
      label: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF8B5CF6),
    );
  }
  if (normalized.contains('shopping')) {
    return const _CategoryMeta(
      label: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFF97316),
    );
  }
  if (normalized.contains('bill')) {
    return const _CategoryMeta(
      label: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFF59E0B),
    );
  }
  if (normalized.contains('health')) {
    return const _CategoryMeta(
      label: 'Health',
      icon: Icons.favorite_outline_rounded,
      color: Color(0xFF10B981),
    );
  }
  return const _CategoryMeta(
    label: 'Others',
    icon: Icons.category_outlined,
    color: Color(0xFF64748B),
  );
}

bool _countsForDashboardExpense(ActivityItem activity) {
  return const {'expense', 'debit', 'lent', 'project'}.contains(activity.type);
}

bool _countsForDashboardIncome(ActivityItem activity) {
  return const {'income', 'credit', 'borrowed'}.contains(activity.type);
}

Color _targetTone(double progress) {
  if (progress >= 1) return AppColors.danger;
  if (progress >= 0.9) return const Color(0xFFF97316);
  if (progress >= 0.7) return AppColors.warning;
  return AppColors.positive;
}

String _targetMessage(double progress) {
  if (progress >= 1) return 'Target exceeded';
  if (progress >= 0.9) return 'Almost reached';
  if (progress >= 0.7) return 'Approaching target';
  return 'Within target';
}
