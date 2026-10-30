import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/db_helper.dart';
import '../services/sms_service.dart';
import '../services/export_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KharchaDostApp());
}

class KharchaDostApp extends StatelessWidget {
  const KharchaDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خرچہ دوست',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D5C3A)),
        useMaterial3: true,
        fontFamily: 'Roboto',
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
  final SmsService _smsService = SmsService();
  double monthlyBudget = 23000.0;
  List<Expense> expenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _smsService.initSmsListener((newExpense) {
      setState(() {
        expenses.add(newExpense);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("SMS سے خودکار خرچہ شامل ہوا: Rs. ${newExpense.extra}"),
          backgroundColor: Colors.teal[800],
        ),
      );
    });
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final yearMonth = DateFormat('yyyy-MM').format(now);
    final data = await DatabaseHelper.instance.getMonthlyExpenses(yearMonth);
    final budgetData = await DatabaseHelper.instance.getBudget(yearMonth);

    setState(() {
      expenses = data;
      monthlyBudget = budgetData['salary'] ?? 23000.0;
      isLoading = false;
    });
  }

  double get totalSpent => expenses.fold(0.0, (sum, item) => sum + item.total);
  double get remainingBalance => monthlyBudget - totalSpent;

  double get dailySafeSpend {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInMonth - now.day) + 1;
    if (remainingDays <= 0) return remainingBalance;
    final safe = remainingBalance / remainingDays;
    return safe > 0 ? safe : 0.0;
  }

  void _showAddExpenseDialog() {
    final rickshawCtrl = TextEditingController();
    final lunchCtrl = TextEditingController();
    final teaCtrl = TextEditingController();
    final genCtrl = TextEditingController();
    final extraCtrl = TextEditingController();
    final extraDetailCtrl = TextEditingController();
    String paymentMode = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("نیا روزانہ خرچہ درج کریں",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D5C3A))),
                const SizedBox(height: 12),
                TextField(controller: rickshawCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "رکشہ کرایہ (Rs)", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: lunchCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "دوپہر کا کھانا / Lunch (Rs)", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: teaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "چائے / Tea (Rs)", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: genCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "عام خرچ / General (Rs)", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: extraCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "اضافی خرچ / Extra (Rs)", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: extraDetailCtrl, decoration: const InputDecoration(labelText: "اضافی خرچ کی تفصیل (مثلاً شاپنگ، دوائی)", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5C3A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final now = DateTime.now();
                    final exp = Expense(
                      date: DateFormat('yyyy-MM-dd').format(now),
                      day: DateFormat('EEEE').format(now),
                      rickshaw: double.tryParse(rickshawCtrl.text) ?? 0.0,
                      lunch: double.tryParse(lunchCtrl.text) ?? 0.0,
                      tea: double.tryParse(teaCtrl.text) ?? 0.0,
                      general: double.tryParse(genCtrl.text) ?? 0.0,
                      extra: double.tryParse(extraCtrl.text) ?? 0.0,
                      extraDetails: extraDetailCtrl.text,
                      paymentMode: paymentMode,
                    );
                    await DatabaseHelper.instance.insertExpense(exp);
                    Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text("محفوظ کریں (Save)"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('خرچہ دوست (Kharcha Dost)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D5C3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'ایکسل فائل بنائیں',
            onPressed: () async {
              final path = await ExportService.generateExcel(expenses, monthlyBudget, DateFormat('MMMM yyyy').format(DateTime.now()));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ایکسل شیٹ محفوظ ہوگئی: $path')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'انوائس سلپ بنائیں',
            onPressed: () => _showInvoiceOptions(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Budget Cards
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("ماہانہ بجٹ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text("Rs. ${currencyFormat.format(monthlyBudget)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("باقی رقم", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text("Rs. ${currencyFormat.format(remainingBalance)}",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: remainingBalance < 3000 ? Colors.red : Colors.green[800])),
                                ],
                              )
                            ],
                          ),
                          const Divider(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.speed, color: Color(0xFF0D5C3A)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "آج خرچ کرنے کی محفوظ حد: Rs. ${dailySafeSpend.toStringAsFixed(0)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D5C3A), fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Daily Transactions List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("حالیہ اخراجات کی تفصیل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("${expenses.length} دن درج", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.reversed.length,
                    itemBuilder: (ctx, idx) {
                      final item = expenses.reversed.toList()[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text("${item.date} (${item.day})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            "رکشہ: ${item.rickshaw.toInt()} | کھانا: ${item.lunch.toInt()} | چائے: ${item.tea.toInt()}" +
                            (item.extra > 0 ? "\nایکسٹرا: ${item.extra.toInt()} (${item.extraDetails})" : ""),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text("Rs. ${item.total.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D5C3A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("خرچہ لکھیں"),
        onPressed: _showAddExpenseDialog,
      ),
    );
  }

  void _showInvoiceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("انوائس سلپ منتخب کریں", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.all_inbox),
                label: const Text("پورے مہینے کی اکٹھی انوائس سلپ"),
                onPressed: () {
                  Navigator.pop(ctx);
                  ExportService.printInvoice(title: "مکمل ماہانہ رپورٹ", expenses: expenses, totalBudget: monthlyBudget);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.emoji_food_beverage),
                label: const Text("صرف چائے (Tea) کی انوائس سلپ"),
                onPressed: () {
                  Navigator.pop(ctx);
                  ExportService.printInvoice(title: "چائے انوائس", expenses: expenses, totalBudget: monthlyBudget, singleCategory: 'Tea');
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.two_wheeler),
                label: const Text("صرف رکشہ کرایہ کی انوائس سلپ"),
                onPressed: () {
                  Navigator.pop(ctx);
                  ExportService.printInvoice(title: "رکشہ انوائس", expenses: expenses, totalBudget: monthlyBudget, singleCategory: 'Rickshaw Fare');
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.restaurant),
                label: const Text("صرف دوپہر کا کھانا (Lunch) کی انوائس سلپ"),
                onPressed: () {
                  Navigator.pop(ctx);
                  ExportService.printInvoice(title: "لنچ انوائس", expenses: expenses, totalBudget: monthlyBudget, singleCategory: 'Lunch');
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.warning_amber),
                label: const Text("صرف ایکسٹرا خرچے (Extra Expense) کی سلپ"),
                onPressed: () {
                  Navigator.pop(ctx);
                  ExportService.printInvoice(title: "ایکسٹرا خرچ انوائس", expenses: expenses, totalBudget: monthlyBudget, singleCategory: 'Extra Expense');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
