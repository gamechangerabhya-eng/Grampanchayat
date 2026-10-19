import 'package:flutter_test/flutter_test.dart';
import 'package:lasalgaon_salary_app/main.dart';

void main() {
  group('Salary calculation', () {
    test('calculates allowances, gross, deductions, and net salary', () {
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
      expect(employee.deductions, closeTo(1199.6, 0.001));
      expect(employee.net, closeTo(18000, 0.001));
    });

    test('includes recovery and employee-specific deductions', () {
      final employee = EmployeeSalary(
        department: Department.waterSupply,
        name: 'Test Employee',
        post: 'व्हॉलमन',
        payScale: '6000-100-18000',
        basic: 7000,
        dearnessAllowance: 3000,
        recovery: 500,
        loan: 1000,
        professionalTax: 200,
        insurance: 300,
        society: 500,
      );

      expect(employee.gross, closeTo(11283.1, 0.001));
      expect(employee.deductions, closeTo(2583.1, 0.001));
      expect(employee.net, closeTo(8200, 0.001));
    });
  });

  group('Formatting', () {
    test('formats Indian currency without locale initialization', () {
      expect(formatIndianCurrency(0), '₹0');
      expect(formatIndianCurrency(1234), '₹1,234');
      expect(formatIndianCurrency(1234567), '₹12,34,567');
      expect(formatIndianCurrency(-123456), '-₹1,23,456');
    });
  });
}
