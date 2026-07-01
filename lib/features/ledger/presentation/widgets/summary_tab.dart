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
    final summaryNet = summaryIncome - summaryExpense;
    final targetMonth = _targetMonthForRange(range);
    final targetMonthKey = _monthKey(targetMonth);
    final targetAmount = widget.monthlyTargets[targetMonthKey];
    final targetExpense = _strictMonthlyExpense(targetMonth);
    final targetProgress = targetAmount == null || targetAmount <= 0
        ? 0.0
        : targetExpense / targetAmount;
    final categoryItems = _categoryBreakdown(expenseActivities);
    final sourceItems = _sourceBreakdown(expenseActivities);
    final recentActivities = filteredActivities.take(6).toList();

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
        _MonthlyTargetHeroCard(
          monthLabel: _monthLabel(targetMonth),
          targetAmount: targetAmount,
          spent: targetExpense,
          progress: targetProgress,
          onSetTarget: () => _showTargetDialog(targetMonthKey, targetAmount),
        ),
        const SizedBox(height: 18),
        _SummaryStatGrid(
          items: [
            _SummaryStatData(
              title: 'Expense',
              subtitle: 'Total spent',
              value: summaryExpense,
              color: AppColors.danger,
              valueColor: AppColors.ink,
              icon: Icons.south_west_rounded,
            ),
            _SummaryStatData(
              title: 'Income',
              subtitle: 'Total received',
              value: summaryIncome,
              color: AppColors.positive,
              valueColor: AppColors.ink,
              icon: Icons.north_east_rounded,
            ),
            _SummaryStatData(
              title: 'Net',
              subtitle: summaryNet >= 0 ? 'Healthy balance' : 'Negative flow',
              value: summaryNet,
              color: summaryNet >= 0 ? AppColors.positive : AppColors.danger,
              valueColor: AppColors.ink,
              icon: Icons.account_balance_wallet_rounded,
            ),
            _SummaryStatData(
              title: 'Target',
              subtitle: targetAmount == null
                  ? 'No target set'
                  : _targetMessage(targetProgress),
              value: targetAmount == null
                  ? null
                  : (targetProgress * 100).clamp(0, 999).toDouble(),
              color: _targetTone(targetProgress),
              valueColor: AppColors.ink,
              icon: Icons.track_changes_rounded,
              suffix: targetAmount == null ? null : '%',
              labelValue: targetAmount == null ? 'Set target' : null,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 760;
            final analyticsCards = [
              _PremiumSectionCard(
                title: 'Category Distribution',
                subtitle: 'Understand where your spending is going.',
                child: _CategoryDistributionSection(items: categoryItems),
              ),
              _PremiumSectionCard(
                title: 'Daily Spending',
                subtitle: 'Track recent movement with flexible views.',
                child: _DailySpendingSection(
                  activities: widget.activities,
                  referenceDate: now,
                ),
              ),
            ];

            if (stacked) {
              return Column(
                children: [
                  analyticsCards[0],
                  const SizedBox(height: 16),
                  analyticsCards[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: analyticsCards[0]),
                const SizedBox(width: 16),
                Expanded(child: analyticsCards[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 760;
            final cards = [
              _PremiumSectionCard(
                title: 'Category Breakdown',
                subtitle: 'Top categories by total spending.',
                child: _CategoryBreakdownSection(items: categoryItems),
              ),
              _PremiumSectionCard(
                title: 'Source Breakdown',
                subtitle: 'Your most-used spending sources.',
                child: _SourceBreakdownSection(
                  items: sourceItems,
                  sources: widget.sources,
                ),
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
    return totals.entries
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
    return totals.entries
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

enum _SummaryChartMode {
  weekly('Weekly'),
  monthly('Monthly'),
  compare('This Month vs Previous');

  const _SummaryChartMode(this.label);

  final String label;
}

class _MonthlyTargetHeroCard extends StatelessWidget {
  const _MonthlyTargetHeroCard({
    required this.monthLabel,
    required this.targetAmount,
    required this.spent,
    required this.progress,
    required this.onSetTarget,
  });

  final String monthLabel;
  final double? targetAmount;
  final double spent;
  final double progress;
  final VoidCallback onSetTarget;

  @override
  Widget build(BuildContext context) {
    final tone = _targetTone(progress);
    final remaining =
        targetAmount == null ? 0.0 : math.max(0.0, targetAmount! - spent);
    final status = _targetMessage(progress);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.subtleShadow.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 16,
            bottom: 16,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: targetAmount == null
                ? _TargetUnsetContent(
                    monthLabel: monthLabel,
                    onSetTarget: onSetTarget,
                  )
                : _TargetConfiguredContent(
                    monthLabel: monthLabel,
                    targetAmount: targetAmount!,
                    spent: spent,
                    remaining: remaining,
                    progress: progress,
                    tone: tone,
                    status: status,
                    onEditTarget: onSetTarget,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TargetUnsetContent extends StatelessWidget {
  const _TargetUnsetContent({
    required this.monthLabel,
    required this.onSetTarget,
  });

  final String monthLabel;
  final VoidCallback onSetTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onSetTarget,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Set Target'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'No target set yet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set a monthly spending limit to see progress, remaining budget, and early warnings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _TargetConfiguredContent extends StatelessWidget {
  const _TargetConfiguredContent({
    required this.monthLabel,
    required this.targetAmount,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.tone,
    required this.status,
    required this.onEditTarget,
  });

  final String monthLabel;
  final double targetAmount;
  final double spent;
  final double remaining;
  final double progress;
  final Color tone;
  final String status;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final percentText = '${(progress * 100).clamp(0, 999).round()}%';
    final headlineStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
          height: 1.05,
          fontSize: 19,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Target',
                    style: headlineStyle,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onEditTarget,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 13, color: tone),
                        const SizedBox(width: 5),
                        Text(
                          'Edit',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tone,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    percentText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tone,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: spent),
          builder: (context, value, child) {
            return Text(
              formatMoney(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 0,
                    fontSize: 22,
                    height: 1.0,
                  ),
            );
          },
        ),
        const SizedBox(height: 1),
        Text(
          'Target: ${formatMoney(targetAmount)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(
            begin: 0,
            end: progress.clamp(0.0, progress > 1 ? progress : 1.0),
          ),
          builder: (context, value, child) {
            final displayProgress = value.clamp(0.0, 1.0);
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: displayProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.altSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(tone),
                  ),
                ),
                if (progress > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Over target by ${formatMoney(spent - targetAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.altSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TargetMiniStat(
                  label: 'Used',
                  value: formatMoney(spent),
                  tone: AppColors.ink,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: AppColors.line,
              ),
              Expanded(
                child: _TargetMiniStat(
                  label: 'Remaining',
                  value: formatMoney(remaining),
                  tone: tone,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              _statusIcon(progress),
              size: 16,
              color: tone,
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(double progress) {
    if (progress > 1) return Icons.cancel_outlined;
    if (progress >= 0.9) return Icons.error_outline_rounded;
    if (progress >= 0.7) return Icons.warning_amber_rounded;
    return Icons.check_circle_outline_rounded;
  }
}

class _TargetMiniStat extends StatelessWidget {
  const _TargetMiniStat({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatData {
  const _SummaryStatData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.valueColor,
    this.value,
    this.suffix,
    this.labelValue,
  });

  final String title;
  final String subtitle;
  final double? value;
  final String? suffix;
  final String? labelValue;
  final Color color;
  final Color? valueColor;
  final IconData icon;
}

class _SummaryStatGrid extends StatelessWidget {
  const _SummaryStatGrid({
    required this.items,
  });

  final List<_SummaryStatData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.42,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _SummaryStatCard(item: items[index]),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.item,
  });

  final _SummaryStatData item;

  @override
  Widget build(BuildContext context) {
    final displayValueColor = item.valueColor ?? AppColors.ink;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 17, color: item.color),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.labelValue != null)
              Text(
                item.labelValue!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              )
            else
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: item.value ?? 0),
                builder: (context, value, child) {
                  final text = item.suffix == '%'
                      ? '${value.round()}%'
                      : formatMoney(value);
                  return Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: displayValueColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          height: 1.0,
                        ),
                  );
                },
              ),
            const Spacer(),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSectionCard extends StatelessWidget {
  const _PremiumSectionCard({
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
                    height: 1.35,
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

class _CategoryDistributionSection extends StatelessWidget {
  const _CategoryDistributionSection({
    required this.items,
  });

  final List<_BreakdownEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyChartState(
        icon: Icons.pie_chart_outline_rounded,
        message:
            'No spending recorded yet.\nStart adding transactions to unlock insights.',
      );
    }

    if (items.length == 1) {
      final item = items.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _categoryMeta(item.label).icon,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      '100% of spending',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(item.value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 1,
              minHeight: 12,
              color: item.color,
              backgroundColor: AppColors.altSurface,
            ),
          ),
        ],
      );
    }

    final topItems = items.take(5).toList();
    return Row(
      children: [
        SizedBox(
          width: 148,
          height: 148,
          child: CustomPaint(
            painter: _DonutChartPainter(items: topItems),
            child: Center(
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.subtleShadow.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Top',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topItems.first.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
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
                  padding: const EdgeInsets.only(bottom: 14),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

class _DailySpendingSection extends StatefulWidget {
  const _DailySpendingSection({
    required this.activities,
    required this.referenceDate,
  });

  final List<ActivityItem> activities;
  final DateTime referenceDate;

  @override
  State<_DailySpendingSection> createState() => _DailySpendingSectionState();
}

class _DailySpendingSectionState extends State<_DailySpendingSection> {
  _SummaryChartMode _mode = _SummaryChartMode.weekly;
  int _selectedIndex = -1;

  @override
  void didUpdateWidget(covariant _DailySpendingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities) {
      _selectedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = _buildChartModel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in _SummaryChartMode.values)
              _RangeChip(
                label: mode.label,
                selected: _mode == mode,
                onTap: () {
                  setState(() {
                    _mode = mode;
                    _selectedIndex = -1;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (model.message != null)
          _EmptyChartState(
            icon: Icons.bar_chart_rounded,
            message: model.message!,
          )
        else
          _ChartBarsView(
            title: model.title,
            subtitle: model.subtitle,
            bars: model.bars,
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
          ),
      ],
    );
  }

  _SpendingChartModel _buildChartModel() {
    final expenses = widget.activities
        .where(_countsForDashboardExpense)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    switch (_mode) {
      case _SummaryChartMode.weekly:
        final bars = _weeklyBars(expenses);
        if (bars.every((bar) => bar.amount <= 0)) {
          return const _SpendingChartModel(
            title: 'Weekly spending',
            subtitle: 'Last 7 days',
            message: 'No weekly spending found yet.',
          );
        }
        return _SpendingChartModel(
          title: 'Weekly spending',
          subtitle: 'Last 7 days',
          bars: bars,
        );
      case _SummaryChartMode.monthly:
        final bars = _monthlyBars(expenses);
        if (bars.every((bar) => bar.amount <= 0)) {
          return const _SpendingChartModel(
            title: 'Monthly spending',
            subtitle: 'Current month by week',
            message: 'No monthly spending found yet.',
          );
        }
        return _SpendingChartModel(
          title: 'Monthly spending',
          subtitle: 'Current month by week',
          bars: bars,
        );
      case _SummaryChartMode.compare:
        final bars = _comparisonBars(expenses);
        final previousAmount = bars.first.amount;
        final currentAmount = bars.last.amount;
        if (currentAmount <= 0 && previousAmount <= 0) {
          return const _SpendingChartModel(
            title: 'This month vs previous month',
            subtitle: 'Month-to-month comparison',
            message: 'No comparison data found yet.',
          );
        }
        if (previousAmount <= 0) {
          return const _SpendingChartModel(
            title: 'This month vs previous month',
            subtitle: 'Month-to-month comparison',
            message: 'Previous month data not found yet.',
          );
        }
        return _SpendingChartModel(
          title: 'This month vs previous month',
          subtitle: 'Month-to-month comparison',
          bars: bars,
        );
    }
  }

  List<_DailySpendBar> _weeklyBars(List<ActivityItem> expenses) {
    final end = DateTime(
      widget.referenceDate.year,
      widget.referenceDate.month,
      widget.referenceDate.day,
    );
    final start = end.subtract(const Duration(days: 6));
    final totals = <DateTime, double>{};

    for (final activity in expenses) {
      final day = DateTime(
        activity.occurredAt.year,
        activity.occurredAt.month,
        activity.occurredAt.day,
      );
      if (day.isBefore(start) || day.isAfter(end)) continue;
      totals.update(
        day,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return _DailySpendBar(
        date: day,
        label: _shortDayLabel(day),
        amount: totals[day] ?? 0,
      );
    });
  }

  List<_DailySpendBar> _monthlyBars(List<ActivityItem> expenses) {
    final now = widget.referenceDate;
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final totals = <int, double>{};

    for (final activity in expenses) {
      final time = activity.occurredAt;
      if (time.isBefore(start) ||
          time.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59))) {
        continue;
      }
      final weekIndex = ((time.day - 1) ~/ 7) + 1;
      totals.update(
        weekIndex,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }

    final totalWeeks = ((end.day - 1) ~/ 7) + 1;
    return List.generate(totalWeeks, (index) {
      final week = index + 1;
      return _DailySpendBar(
        date: start.add(Duration(days: index * 7)),
        label: 'W$week',
        amount: totals[week] ?? 0,
      );
    });
  }

  List<_DailySpendBar> _comparisonBars(List<ActivityItem> expenses) {
    final now = widget.referenceDate;
    final currentStart = DateTime(now.year, now.month, 1);
    final currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final previousStart = DateTime(now.year, now.month - 1, 1);
    final previousEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    var currentTotal = 0.0;
    var previousTotal = 0.0;

    for (final activity in expenses) {
      final time = activity.occurredAt;
      if (!time.isBefore(currentStart) && !time.isAfter(currentEnd)) {
        currentTotal += activity.amount.abs();
      } else if (!time.isBefore(previousStart) && !time.isAfter(previousEnd)) {
        previousTotal += activity.amount.abs();
      }
    }

    return [
      _DailySpendBar(
        date: previousStart,
        label: _monthShort(previousStart),
        amount: previousTotal,
      ),
      _DailySpendBar(
        date: currentStart,
        label: _monthShort(currentStart),
        amount: currentTotal,
      ),
    ];
  }

  String _shortDayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  String _monthShort(DateTime date) {
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
    return months[date.month - 1];
  }
}

class _ChartBarsView extends StatelessWidget {
  const _ChartBarsView({
    required this.title,
    required this.subtitle,
    required this.bars,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<_DailySpendBar> bars;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(
      0,
      (current, bar) => math.max(current, bar.amount),
    );
    final midValue = maxValue / 2;
    final effectiveSelected =
        (selectedIndex >= 0 && selectedIndex < bars.length)
            ? selectedIndex
            : bars.lastIndexWhere((bar) => bar.amount > 0);
    final selectedBar =
        effectiveSelected >= 0 ? bars[effectiveSelected] : bars.last;
    final activeBars = bars.where((bar) => bar.amount > 0).toList();

    if (activeBars.length <= 1) {
      final singleBar = activeBars.isEmpty ? bars.last : activeBars.first;
      return _SingleDaySpendingState(
        title: title,
        subtitle: subtitle,
        bar: singleBar,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.altSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subtitle • ${selectedBar.label}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(selectedBar.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _axisLabel(context, formatMoney(maxValue)),
                    _axisLabel(context, formatMoney(midValue)),
                    _axisLabel(context, '৳0'),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < bars.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onSelect(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: effectiveSelected == i ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: FittedBox(
                                      child: Text(
                                        bars[i].amount <= 0
                                            ? '৳0'
                                            : formatMoney(bars[i].amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.ink,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 320),
                                      curve: Curves.easeOutCubic,
                                      width: effectiveSelected == i ? 24 : 18,
                                      height: maxValue == 0
                                          ? 10
                                          : math.max(
                                              10,
                                              (bars[i].amount / maxValue) * 138,
                                            ),
                                      decoration: BoxDecoration(
                                        color: effectiveSelected == i
                                            ? AppColors.primary
                                            : AppColors.primary
                                                .withValues(alpha: 0.32),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        boxShadow: effectiveSelected == i
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  bars[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: effectiveSelected == i
                                            ? AppColors.ink
                                            : AppColors.mutedInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _axisLabel(BuildContext context, String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedInk,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SingleDaySpendingState extends StatelessWidget {
  const _SingleDaySpendingState({
    required this.title,
    required this.subtitle,
    required this.bar,
  });

  final String title;
  final String subtitle;
  final _DailySpendBar bar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subtitle • ${bar.label}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(bar.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 1,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingChartModel {
  const _SpendingChartModel({
    required this.title,
    required this.subtitle,
    this.bars = const [],
    this.message,
  });

  final String title;
  final String subtitle;
  final List<_DailySpendBar> bars;
  final String? message;
}

class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({
    required this.items,
  });

  final List<_BreakdownEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyCardMessage(
        message: 'No spending recorded yet.',
      );
    }

    return Column(
      children: [
        for (final item in items.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _RankedBreakdownRow(
              label: item.label,
              value: item.value,
              share: item.share,
              color: item.color,
              icon: _categoryMeta(item.label).icon,
            ),
          ),
      ],
    );
  }
}

class _SourceBreakdownSection extends StatelessWidget {
  const _SourceBreakdownSection({
    required this.items,
    required this.sources,
  });

  final List<_BreakdownEntry> items;
  final List<MoneySource> sources;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyCardMessage(
        message: 'Source usage will appear after expenses are added.',
      );
    }

    return Column(
      children: [
        for (final item in items.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SourceRankedRow(
              item: item,
              source: sources.firstWhere(
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
          ),
      ],
    );
  }
}

class _RankedBreakdownRow extends StatelessWidget {
  const _RankedBreakdownRow({
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: share.clamp(0, 1),
                    minHeight: 8,
                    color: color,
                    backgroundColor: Colors.white,
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
                formatMoney(value),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(share * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRankedRow extends StatelessWidget {
  const _SourceRankedRow({
    required this.item,
    required this.source,
  });

  final _BreakdownEntry item;
  final MoneySource source;

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(item.value),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(item.share * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCardMessage extends StatelessWidget {
  const _EmptyCardMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.altSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w600,
            ),
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Range',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Filter your dashboard using a date range.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final filter in SummaryFilter.values)
                _RangeChip(
                  label: filter.label,
                  selected: selected == filter,
                  onTap: () async {
                    if (filter == SummaryFilter.custom) {
                      Navigator.of(context).pop(filter);
                      await onCustomRangeTap();
                      return;
                    }
                    Navigator.of(context).pop(filter);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.altSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.24)
                : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
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
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == null
          ? ''
          : widget.initialValue!.round().toString(),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.mutedInk, size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.4,
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
    const strokeWidth = 18.0;
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
        items.length == 1 ? sweep : math.max(sweep - 0.05, 0.0),
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
    required this.date,
    required this.label,
    required this.amount,
  });

  final DateTime date;
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
  if (progress > 1.0) return AppColors.primaryDark;
  if (progress >= 0.9) return AppColors.danger;
  if (progress >= 0.7) return AppColors.warning;
  return AppColors.positive;
}

String _targetMessage(double progress) {
  if (progress > 1.0) return 'Target exceeded';
  if (progress >= 0.9) return 'Almost reached';
  if (progress >= 0.7) return 'Approaching target';
  return 'Within target';
}
