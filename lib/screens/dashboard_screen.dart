import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../services/db_helper.dart';
import '../services/export_service.dart';

class KharchaDostApp extends StatelessWidget {
  const KharchaDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharcha Dost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _rickshawController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _teaController = TextEditingController();
  final TextEditingController _generalController = TextEditingController();
  final TextEditingController _extraController = TextEditingController();
  final TextEditingController _extraDetailsController = TextEditingController();

  List<Expense> _expenses = [];
  double _salary = 23000.0;
  double _fixedBills = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final monthlyExpenses = await _db.getMonthlyExpenses(monthKey);
    final budget = await _db.getBudget(monthKey);

    if (!mounted) return;

    setState(() {
      _expenses = monthlyExpenses;
      _salary = budget['salary'] ?? 23000.0;
      _fixedBills = budget['fixed_bills'] ?? 0.0;
      _isLoading = false;
    });
  }

  Future<void> _addExpense() async {
    final expense = Expense(
      date: _dateController.text,
      day: DateFormat('EEEE').format(DateTime.parse(_dateController.text)),
      rickshaw: double.tryParse(_rickshawController.text) ?? 0.0,
      lunch: double.tryParse(_lunchController.text) ?? 0.0,
      tea: double.tryParse(_teaController.text) ?? 0.0,
      general: double.tryParse(_generalController.text) ?? 0.0,
      extra: double.tryParse(_extraController.text) ?? 0.0,
      extraDetails: _extraDetailsController.text,
      paymentMode: 'Cash',
    );

    await _db.insertExpense(expense);
    _clearForm();
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense saved successfully.')),
    );
  }

  Future<void> _exportExcel() async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final path = await ExportService.generateExcel(_expenses, _salary, monthKey);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel export created: $path')),
    );
  }

  void _clearForm() {
    _rickshawController.clear();
    _lunchController.clear();
    _teaController.clear();
    _generalController.clear();
    _extraController.clear();
    _extraDetailsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _expenses.fold<double>(0, (sum, item) => sum + item.total);
    final remaining = (_salary - _fixedBills) - totalSpent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kharcha Dost'),
        actions: [
          IconButton(
            onPressed: _exportExcel,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly overview',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Salary'),
                              Text('Rs. ${_salary.toStringAsFixed(0)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fixed bills'),
                              Text('Rs. ${_fixedBills.toStringAsFixed(0)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Spent'),
                              Text('Rs. ${totalSpent.toStringAsFixed(0)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining'),
                              Text('Rs. ${remaining.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add expense',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Date'),
                  ),
                  const SizedBox(height: 8),
                  _buildNumberField('Rickshaw', _rickshawController),
                  _buildNumberField('Lunch', _lunchController),
                  _buildNumberField('Tea', _teaController),
                  _buildNumberField('General', _generalController),
                  _buildNumberField('Extra', _extraController),
                  TextField(
                    controller: _extraDetailsController,
                    decoration: const InputDecoration(labelText: 'Extra details'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addExpense,
                      child: const Text('Save expense'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recent entries',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_expenses.isEmpty)
                    const Text('No expenses yet.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final item = _expenses[index];
                        return Card(
                          child: ListTile(
                            title: Text('${item.date} • ${item.day}'),
                            subtitle: Text('Total: Rs. ${item.total.toStringAsFixed(2)}'),
                            trailing: Text(item.paymentMode),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _rickshawController.dispose();
    _lunchController.dispose();
    _teaController.dispose();
    _generalController.dispose();
    _extraController.dispose();
    _extraDetailsController.dispose();
    super.dispose();
  }
}
