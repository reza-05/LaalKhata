import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laalkhata/features/ledger/presentation/widgets/summary_tab.dart';

void main() {
  testWidgets('renders SummaryTab with no data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryTab(
            sources: const [],
            activities: const [],
            monthlyTargets: const {},
            onSaveMonthlyTarget: (monthKey, amount) async {},
            onViewActivities: () {},
          ),
        ),
      ),
    );

    // Let the animations settle
    await tester.pumpAndSettle();

    // Verify header title and subtitle
    expect(find.text('Summary'), findsOneWidget);
    expect(find.textContaining('Spending analysis'), findsOneWidget);
  });
}
