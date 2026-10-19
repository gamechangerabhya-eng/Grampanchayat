import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const LasalgaonSalaryApp());

const _green = Color(0xFF176B45);
const _darkGreen = Color(0xFF0D3D2B);
const _saffron = Color(0xFFE69A2D);
const _surface = Color(0xFFF5F8F6);
const _photoUrl =
    'https://images.tv9marathi.com/wp-content/uploads/2022/04/12213120/New-Project-3-13.jpg';

enum Department { gramNidhi, waterSupply }

extension DepartmentText on Department {
  String get mr => this == Department.gramNidhi ? 'ग्रामनिधी' : 'पाणी पुरवठा';
  IconData get icon => this == Department.gramNidhi ? Icons.account_balance_rounded : Icons.water_drop_rounded;
}

class EmployeeSalary {
  EmployeeSalary({
    required this.department,
    required this.name,
    required this.post,
    required this.payScale,
    required this.basic,
    this.dearnessAllowance = 0,
    this.recovery = 0,
    this.loan = 0,
    this.professionalTax = 200,
    this.insurance = 0,
    this.advance = 0,
    this.grainAdvance = 0,
    this.society = 0,
    this.other = 0,
  });

  final Department department;
  final String name;
  final String post;
  final String payScale;
  final double basic;
  double dearnessAllowance;
  double recovery;
  double loan;
  double professionalTax;
  double insurance;
  double advance;
  double grainAdvance;
  double society;
  double other;

  double get livingAllowance => basic * .10;
  double get gpContribution => basic * .0833;
  double get gross => basic + livingAllowance + dearnessAllowance + gpContribution;
  double get balanceAfterRecovery => gross - recovery;
  double get deductions => gpContribution + loan + professionalTax + insurance + advance + grainAdvance + society + other;
  double get net => balanceAfterRecovery - deductions;
  bool get needsReview => dearnessAllowance == 0 || net < 0 || basic <= 0;
}

class LasalgaonSalaryApp extends StatelessWidget {
  const LasalgaonSalaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'लासलगाव ग्रामपंचायत वेतन प्रणाली',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _green, primary: _green, secondary: _saffron, surface: Colors.white),
        scaffoldBackgroundColor: _surface,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E7E2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E7E2))),
        ),
        cardTheme: CardTheme(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: const SalaryHomePage(),
    );
  }
}

class SalaryHomePage extends StatefulWidget {
  const SalaryHomePage({super.key});
  @override
  State<SalaryHomePage> createState() => _SalaryHomePageState();
}

class _SalaryHomePageState extends State<SalaryHomePage> {
  final List<EmployeeSalary> _employees = [];
  int _step = 0;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _busy = false;
  String? _message;

  List<EmployeeSalary> _of(Department d) => _employees.where((e) => e.department == d).toList();
  double _sum(Iterable<double> values) => values.fold(0, (a, b) => a + b);

  Future<void> _import(Department department) async {
    setState(() { _busy = true; _message = null; });
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['xlsx', 'csv'], withData: true);
      if (picked == null) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('फाइल वाचता आली नाही.');
      final rows = file.extension?.toLowerCase() == 'csv' ? _readCsv(bytes) : _readXlsx(bytes);
      if (rows.isEmpty) throw Exception('वैध कर्मचारी नोंदी सापडल्या नाहीत.');
      setState(() {
        _employees.removeWhere((e) => e.department == department);
        _employees.addAll(rows.map((row) => EmployeeSalary(
          department: department,
          name: row[0],
          post: row[1],
          payScale: row[2],
          basic: double.parse(row[3]),
        )));
        _message = '${department.mr}: ${rows.length} कर्मचारी सुरक्षितपणे ब्राउझरमध्ये वाचले.';
      });
    } catch (e) {
      setState(() => _message = 'आयात अयशस्वी: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<List<String>> _readCsv(Uint8List bytes) {
    final lines = const LineSplitter().convert(utf8.decode(bytes));
    if (lines.length < 2) return [];
    return lines.skip(1).map((line) => line.split(',').map((v) => v.trim()).toList()).where((r) => r.length >= 4 && double.tryParse(r[3]) != null).map((r) => r.take(4).toList()).toList();
  }

  List<List<String>> _readXlsx(Uint8List bytes) {
    final book = Excel.decodeBytes(bytes);
    if (book.tables.isEmpty) return [];
    final sheet = book.tables.values.first;
    final output = <List<String>>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final values = List.generate(4, (j) => j < row.length ? (row[j]?.value?.toString() ?? '').trim() : '');
      if (values[0].isNotEmpty && double.tryParse(values[3].replaceAll(',', '')) != null) {
        values[3] = values[3].replaceAll(',', '');
        output.add(values);
      }
    }
    return output;
  }

  void _downloadTemplate(Department department) {
    final csv = '\uFEFFनाव,पद,वेतनश्रेणी किंवा विशेष वेतन,वेतन\nउदाहरण कर्मचारी,लिपिक,9000-100-22000,12000\n';
    _downloadBytes(Uint8List.fromList(utf8.encode(csv)), '${department == Department.gramNidhi ? 'gramnidhi' : 'pani_puravatha'}_input_template.csv', 'text/csv');
  }

  void _exportWorkbook() {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    for (final department in Department.values) {
      final sheet = excel[department.mr];
      final headers = ['अ.नं.', 'नाव', 'पद', 'वेतनश्रेणी किंवा विशेष वेतन', 'वेतन', 'राहणीमान भत्ता 10%', 'महागाई / सानुग्रह अनुदान', 'ग्रामपंचायत हिस्सा 8.33%', 'एकूण', 'वसुली व दंड', 'हप्ता', 'व्यवसाय कर', 'विमा', 'सन अग्रिम', 'धान्य अग्रिम', 'कर्मचारी सोसायटी', 'इतर', 'एकूण वजाती', 'निव्वळ रक्कम'];
      sheet.appendRow(headers.map(TextCellValue.new).toList());
      final data = _of(department);
      for (var i = 0; i < data.length; i++) {
        final e = data[i];
        sheet.appendRow([
          IntCellValue(i + 1), TextCellValue(e.name), TextCellValue(e.post), TextCellValue(e.payScale), DoubleCellValue(e.basic), DoubleCellValue(e.livingAllowance), DoubleCellValue(e.dearnessAllowance), DoubleCellValue(e.gpContribution), DoubleCellValue(e.gross), DoubleCellValue(e.recovery), DoubleCellValue(e.loan), DoubleCellValue(e.professionalTax), DoubleCellValue(e.insurance), DoubleCellValue(e.advance), DoubleCellValue(e.grainAdvance), DoubleCellValue(e.society), DoubleCellValue(e.other), DoubleCellValue(e.deductions), DoubleCellValue(e.net),
        ]);
      }
      if (data.isNotEmpty) {
        sheet.appendRow([TextCellValue('एकूण'), ...List.generate(3, (_) => TextCellValue('')), ...List.generate(15, (index) {
          final selectors = <double Function(EmployeeSalary)>[(e) => e.basic, (e) => e.livingAllowance, (e) => e.dearnessAllowance, (e) => e.gpContribution, (e) => e.gross, (e) => e.recovery, (e) => e.loan, (e) => e.professionalTax, (e) => e.insurance, (e) => e.advance, (e) => e.grainAdvance, (e) => e.society, (e) => e.other, (e) => e.deductions, (e) => e.net];
          return DoubleCellValue(_sum(data.map(selectors[index])));
        })]);
      }
    }
    final bytes = excel.save();
    if (bytes != null) _downloadBytes(Uint8List.fromList(bytes), 'Lasalgaon_Salary_${_year}_${_month.toString().padLeft(2, '0')}.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  void _downloadBytes(Uint8List bytes, String name, String mime) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _clearSession() => setState(() { _employees.clear(); _step = 0; _message = 'सत्रातील सर्व कर्मचारी माहिती हटवली.'; });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('लासलगाव ग्रामपंचायत', style: TextStyle(fontWeight: FontWeight.w800)), Text('कर्मचारी वेतन व्यवस्थापन प्रणाली', style: TextStyle(fontSize: 12, color: Color(0xFFD2E7DD)))]),
        actions: [if (_employees.isNotEmpty) IconButton(tooltip: 'सत्र साफ करा', onPressed: _clearSession, icon: const Icon(Icons.delete_sweep_outlined))],
      ),
      body: Column(children: [
        Container(
          color: const Color(0xFFE8F4EE), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: const Row(children: [Icon(Icons.lock_outline, color: _green, size: 18), SizedBox(width: 8), Expanded(child: Text('खाजगी व सुरक्षित: सर्व प्रक्रिया या ब्राउझरमध्ये होते. कोणतीही पगार माहिती सर्व्हर किंवा GitHub वर जतन केली जात नाही.', style: TextStyle(color: _darkGreen, fontWeight: FontWeight.w600)))]),
        ),
        Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(compact ? 14 : 26), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Hero(compact: compact),
          const SizedBox(height: 22),
          _StepHeader(step: _step),
          const SizedBox(height: 18),
          if (_message != null) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDDE8E1))), child: Row(children: [const Icon(Icons.info_outline, color: _green), const SizedBox(width: 10), Expanded(child: Text(_message!))])),
          if (_step == 0) _setup(compact) else if (_step == 1) _review() else _summary(compact),
        ]))))),
      ]),
    );
  }

  Widget _setup(bool compact) {
    final cards = Department.values.map((d) => _ImportCard(department: d, count: _of(d).length, busy: _busy, onImport: () => _import(d), onTemplate: () => _downloadTemplate(d))).toList();
    return Column(children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Wrap(spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: compact ? 145 : 220, child: DropdownButtonFormField<int>(value: _month, decoration: const InputDecoration(labelText: 'महिना'), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat.MMMM('mr').format(DateTime(2020, i + 1))))), onChanged: (v) => setState(() => _month = v!))),
        SizedBox(width: compact ? 145 : 180, child: DropdownButtonFormField<int>(value: _year, decoration: const InputDecoration(labelText: 'वर्ष'), items: List.generate(6, (i) => DropdownMenuItem(value: DateTime.now().year - 2 + i, child: Text('${DateTime.now().year - 2 + i}'))), onChanged: (v) => setState(() => _year = v!))),
      ]))),
      const SizedBox(height: 16),
      if (compact) ...cards.expand((c) => [c, const SizedBox(height: 14)]) else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: cards[0]), const SizedBox(width: 16), Expanded(child: cards[1])]),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _employees.isEmpty ? null : () => setState(() => _step = 1), icon: const Icon(Icons.arrow_forward), label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('तपासणीसाठी पुढे जा', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))))),
    ]);
  }

  Widget _review() {
    return Column(children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('कर्मचारी तपासणी', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('महागाई/सानुग्रह अनुदान व कर्मचारीनिहाय कपाती मूलभूत वेतनातून निश्चित होत नाहीत. अंतिम Excel पूर्वी त्यांची नोंद तपासा.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        ..._employees.asMap().entries.map((entry) => _EmployeeTile(employee: entry.value, onChanged: () => setState(() {}))),
      ]))),
      const SizedBox(height: 16),
      Row(children: [OutlinedButton.icon(onPressed: () => setState(() => _step = 0), icon: const Icon(Icons.arrow_back), label: const Text('मागे')), const Spacer(), FilledButton.icon(onPressed: () => setState(() => _step = 2), icon: const Icon(Icons.check_circle_outline), label: const Text('सारांश पहा'))]),
    ]);
  }

  Widget _summary(bool compact) {
    final totalGross = _sum(_employees.map((e) => e.gross));
    final totalDed = _sum(_employees.map((e) => e.deductions + e.recovery));
    final totalNet = _sum(_employees.map((e) => e.net));
    final metrics = [
      _Metric('कर्मचारी', '${_employees.length}', Icons.groups_rounded, _green),
      _Metric('एकूण वेतन', NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalGross), Icons.payments_outlined, const Color(0xFF2463A8)),
      _Metric('एकूण वजाती', NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalDed), Icons.remove_circle_outline, const Color(0xFFB66B16)),
      _Metric('निव्वळ रक्कम', NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalNet), Icons.verified_outlined, _green),
    ];
    return Column(children: [
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: compact ? 2 : 4, childAspectRatio: compact ? 1.25 : 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12, children: metrics),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: Department.values.map((d) { final list = _of(d); return ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFFE8F4EE), child: Icon(d.icon, color: _green)), title: Text(d.mr, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${list.length} कर्मचारी'), trailing: Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_sum(list.map((e) => e.net))), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))); }).toList()))),
      const SizedBox(height: 16),
      Row(children: [OutlinedButton.icon(onPressed: () => setState(() => _step = 1), icon: const Icon(Icons.arrow_back), label: const Text('सुधारणा')), const Spacer(), FilledButton.icon(onPressed: _exportWorkbook, icon: const Icon(Icons.download_rounded), label: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Excel तयार करा')))]),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 210 : 260,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: _darkGreen, image: const DecorationImage(image: NetworkImage(_photoUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0xAA0D3D2B), BlendMode.darken))),
    padding: EdgeInsets.all(compact ? 20 : 32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _saffron, borderRadius: BorderRadius.circular(20)), child: const Text('डिजिटल वेतन सेवा', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
      const SizedBox(height: 12),
      Text('सोपे. सुरक्षित. अचूक.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: compact ? 28 : 38)),
      const SizedBox(height: 5),
      const Text('कर्मचारी माहिती आयात करा, तपासा आणि Excel तयार करा.', style: TextStyle(color: Color(0xFFE6F1EC), fontSize: 16)),
    ]),
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['माहिती आयात', 'तपासणी', 'सारांश व डाउनलोड'];
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: i <= step ? _green : const Color(0xFFD6DDD8),
                child: i < step
                    ? const Icon(Icons.check, color: Colors.white, size: 17)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i <= step ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                    color: i <= step ? _darkGreen : Colors.black45,
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.department, required this.count, required this.busy, required this.onImport, required this.onTemplate});
  final Department department;
  final int count;
  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onTemplate;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [CircleAvatar(radius: 24, backgroundColor: const Color(0xFFE8F4EE), child: Icon(department.icon, color: _green)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(department.mr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(count == 0 ? 'फाइल अद्याप निवडलेली नाही' : '$count कर्मचारी आयात झाले', style: TextStyle(color: count == 0 ? Colors.black54 : _green, fontWeight: FontWeight.w600))]))]),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)), child: const Text('स्तंभ क्रम: नाव → पद → वेतनश्रेणी किंवा विशेष वेतन → वेतन', style: TextStyle(height: 1.4))),
    const SizedBox(height: 16),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : onImport, icon: const Icon(Icons.upload_file_rounded), label: const Text('Excel / CSV निवडा'))),
    Align(alignment: Alignment.center, child: TextButton.icon(onPressed: onTemplate, icon: const Icon(Icons.download_for_offline_outlined), label: const Text('रिकामा नमुना डाउनलोड करा'))),
  ])));
}

class _EmployeeTile extends StatefulWidget {
  const _EmployeeTile({required this.employee, required this.onChanged});
  final EmployeeSalary employee;
  final VoidCallback onChanged;
  @override State<_EmployeeTile> createState() => _EmployeeTileState();
}

class _EmployeeTileState extends State<_EmployeeTile> {
  late final TextEditingController da = TextEditingController(text: widget.employee.dearnessAllowance.toStringAsFixed(0));
  late final TextEditingController recovery = TextEditingController(text: widget.employee.recovery.toStringAsFixed(0));
  late final TextEditingController loan = TextEditingController(text: widget.employee.loan.toStringAsFixed(0));
  late final TextEditingController tax = TextEditingController(text: widget.employee.professionalTax.toStringAsFixed(0));
  late final TextEditingController insurance = TextEditingController(text: widget.employee.insurance.toStringAsFixed(0));
  late final TextEditingController society = TextEditingController(text: widget.employee.society.toStringAsFixed(0));
  double _n(TextEditingController c) => double.tryParse(c.text) ?? 0;
  void _sync() { final e = widget.employee; e.dearnessAllowance = _n(da); e.recovery = _n(recovery); e.loan = _n(loan); e.professionalTax = _n(tax); e.insurance = _n(insurance); e.society = _n(society); widget.onChanged(); }
  @override
  Widget build(BuildContext context) { final e = widget.employee; return ExpansionTile(tilePadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: e.needsReview ? const Color(0xFFFFE9CC) : const Color(0xFFE8F4EE), child: Icon(e.needsReview ? Icons.priority_high : Icons.check, color: e.needsReview ? const Color(0xFF9C5B08) : _green)), title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${e.department.mr} • ${e.post} • ₹${e.basic.toStringAsFixed(0)}'), trailing: Text('₹${e.net.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)), children: [Padding(padding: const EdgeInsets.only(bottom: 16), child: Wrap(spacing: 10, runSpacing: 10, children: [
    _field('महागाई / अनुदान', da), _field('वसुली व दंड', recovery), _field('हप्ता', loan), _field('व्यवसाय कर', tax), _field('विमा', insurance), _field('कर्मचारी सोसायटी', society),
  ]))]); }
  Widget _field(String label, TextEditingController c) => SizedBox(width: 180, child: TextField(controller: c, keyboardType: TextInputType.number, onChanged: (_) => _sync(), decoration: InputDecoration(labelText: label, prefixText: '₹ ')));
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label; final String value; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color), const Spacer(), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)), Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))])));
}
