import 'package:flutter_test/flutter_test.dart';
import 'package:lasalgaon_salary_app/main.dart';

void main() {
  testWidgets('shows Lasalgaon salary home', (tester) async {
    await tester.pumpWidget(const LasalgaonSalaryApp());
    await tester.pump();

    expect(find.text('लासलगाव ग्रामपंचायत'), findsOneWidget);
    expect(find.text('माहिती आयात'), findsOneWidget);
    expect(find.text('ग्रामनिधी'), findsOneWidget);
    expect(find.text('पाणी पुरवठा'), findsOneWidget);
  });

  test('salary calculation produces expected values', () {
    final employee = EmployeeSalary(
      department: Department.gramNidhi,
      name: 'Test Employee',
      post: 'लिपिक',
      payScale: '9000-100-22000',
      basic: 12000,
      dearnessAllowance: 5000,
      professionalTax: 200,
    );

    expect(employee.livingAllowance, 1200);
    expect(employee.gpContribution, closeTo(999.6, 0.001));
    expect(employee.gross, closeTo(19199.6, 0.001));
    expect(employee.net, closeTo(18000, 0.001));
  });
}
