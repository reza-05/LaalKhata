import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laalkhata/app.dart';

void main() {
  testWidgets('shows LaalKhata auth screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LaalKhataApp()));

    expect(find.text('LaalKhata'), findsOneWidget);
    expect(find.text('Digital Expense Notebook for IUTians'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
