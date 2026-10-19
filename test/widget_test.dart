import 'package:flutter_test/flutter_test.dart';
import 'package:lasalgaon_salary_app/main.dart';

void main() {
  testWidgets('shows Lasalgaon salary home', (tester) async {
    await tester.pumpWidget(const LasalgaonSalaryApp());
    expect(find.text('लासलगाव ग्रामपंचायत'), findsOneWidget);
    expect(find.text('माहिती आयात'), findsOneWidget);
  });
}
