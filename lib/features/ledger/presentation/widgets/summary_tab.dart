import 'package:flutter/material.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/presentation/models/ledger_presentation_models.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/ledger_layout_widgets.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/provider_logo.dart';

class SummaryTab extends StatelessWidget {
  const SummaryTab({
    super.key,
    required this.sources,
    required this.activities,
  });

  final List<MoneySource> sources;
  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const PageTitle(
          title: 'Summary',
          subtitle: 'Spending analysis and target progress',
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          const EmptyInsightCard()
        else ...[
          const FilterPillRow(items: ['This Month', 'Daily', 'Sources']),
          const SizedBox(height: 16),
          SummaryHeroCard(activities: activities),
          const SizedBox(height: 16),
          BreakdownCard(
            title: 'Source Breakdown',
            items: sources
                .where((source) => source.balance != null)
                .map(
                  (source) => BreakdownItem(
                    label: source.name,
                    value: source.balance ?? 0,
                    color: source.color,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          BreakdownCard(
            title: 'Category Breakdown',
            items: _categoryBreakdown(),
          ),
        ],
      ],
    );
  }

  List<BreakdownItem> _categoryBreakdown() {
    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.accent,
      AppColors.positive,
      const Color(0xFF2563EB),
    ];
    final totals = <String, double>{};
    for (final activity in activities.where(isExpenseActivity)) {
      totals.update(
        activity.category,
        (value) => value + activity.amount.abs(),
        ifAbsent: () => activity.amount.abs(),
      );
    }
    var index = 0;
    return totals.entries.map((entry) {
      final item = BreakdownItem(
        label: entry.key,
        value: entry.value,
        color: colors[index % colors.length],
      );
      index++;
      return item;
    }).toList();
  }
}

class MetricText extends StatelessWidget {
  const MetricText({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class SummaryHeroCard extends StatelessWidget {
  const SummaryHeroCard({
    super.key,
    required this.activities,
  });

  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final expense = activities
        .where(isExpenseActivity)
        .fold(0.0, (sum, activity) => sum + activity.amount.abs());
    final income = activities
        .where(isIncomeActivity)
        .fold(0.0, (sum, activity) => sum + activity.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: MetricText(
                label: 'Monthly Expense',
                value: formatMoney(expense),
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.line),
            const SizedBox(width: 16),
            Expanded(
              child: MetricText(
                label: 'Income vs Expense',
                value: formatMoney(income - expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyInsightCard extends StatelessWidget {
  const EmptyInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const IconBubble(
              icon: Icons.query_stats_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No summary yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your charts and breakdowns will appear after you add real transactions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class BreakdownCard extends StatelessWidget {
  const BreakdownCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<BreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (sum, item) => sum + item.value);

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
            const SizedBox(height: 16),
            for (final item in items) ...[
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    total == 0
                        ? '0%'
                        : '${((item.value / total) * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatMoney(item.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : item.value / total,
                  minHeight: 8,
                  color: item.color,
                  backgroundColor: AppColors.line,
                ),
              ),
              if (item != items.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class FilterPillRow extends StatelessWidget {
  const FilterPillRow({
    super.key,
    required this.items,
  });

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          Chip(
            label: Text(items[i]),
            backgroundColor: i == 0 ? AppColors.primary : AppColors.card,
            labelStyle: TextStyle(
              color: i == 0 ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: i == 0 ? AppColors.primary : AppColors.line,
            ),
          ),
      ],
    );
  }
}
