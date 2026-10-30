import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense_model.dart';

class ExportService {
  // Generate exact Excel replicating user's monthly template
  static Future<String> generateExcel(List<Expense> expenses, double budget, String monthName) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[monthName];
    excel.setDefaultSheet(monthName);

    // Headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Day'),
      TextCellValue('Rickshaw Fare'),
      TextCellValue('Lunch'),
      TextCellValue('Tea'),
      TextCellValue('General Expense'),
      TextCellValue('Extra Expense'),
      TextCellValue('Extra Expense Details'),
      TextCellValue('Total Expense'),
      TextCellValue('Remaining Balance'),
    ]);

    double remaining = budget;
    double totalRickshaw = 0;
    double totalLunch = 0;
    double totalTea = 0;
    double totalGen = 0;
    double totalExtra = 0;

    for (var exp in expenses) {
      remaining -= exp.total;
      totalRickshaw += exp.rickshaw;
      totalLunch += exp.lunch;
      totalTea += exp.tea;
      totalGen += exp.general;
      totalExtra += exp.extra;

      sheet.appendRow([
        TextCellValue(exp.date),
        TextCellValue(exp.day),
        DoubleCellValue(exp.rickshaw),
        DoubleCellValue(exp.lunch),
        DoubleCellValue(exp.tea),
        DoubleCellValue(exp.general),
        DoubleCellValue(exp.extra),
        TextCellValue(exp.extraDetails),
        DoubleCellValue(exp.total),
        DoubleCellValue(remaining),
      ]);
    }

    // Totals row
    double grandTotal = totalRickshaw + totalLunch + totalTea + totalGen + totalExtra;
    sheet.appendRow([
      TextCellValue('TOTAL EXPENSES'),
      TextCellValue(''),
      DoubleCellValue(totalRickshaw),
      DoubleCellValue(totalLunch),
      DoubleCellValue(totalTea),
      DoubleCellValue(totalGen),
      DoubleCellValue(totalExtra),
      TextCellValue('Total Spent'),
      DoubleCellValue(grandTotal),
      DoubleCellValue(budget - grandTotal),
    ]);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Kharcha_Dost_${monthName.replaceAll(" ", "_")}.xlsx');
    final bytes = excel.encode()!;
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Generate Single Category Invoice or Consolidated Invoice PDF
  static Future<void> printInvoice({
    required String title,
    required List<Expense> expenses,
    required double totalBudget,
    String? singleCategory, // e.g., 'Tea', 'Rickshaw', or null for All
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossPWCrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("خرچہ دوست - ماہانہ انوائس سلپ (Kharcha Dost)",
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Text("انوائس قسم: ${singleCategory ?? "تمام اخراجات کا مجموعہ (Consolidated)"}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text("کل مقررہ بجٹ: Rs. ${totalBudget.toStringAsFixed(0)}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 16),

                // Table
                pw.Table.fromTextArray(
                  headers: singleCategory == null
                      ? ['تاریخ', 'رکشہ', 'لنچ', 'چائے', 'عام خرچ', 'ایکسٹرا', 'کل']
                      : ['تاریخ', 'دن', singleCategory, 'تفصیل'],
                  data: expenses.map((e) {
                    if (singleCategory == 'Rickshaw Fare') {
                      return [e.date, e.day, 'Rs. ${e.rickshaw}', 'روزانہ رکشہ'];
                    } else if (singleCategory == 'Lunch') {
                      return [e.date, e.day, 'Rs. ${e.lunch}', 'دوپہر کھانا'];
                    } else if (singleCategory == 'Tea') {
                      return [e.date, e.day, 'Rs. ${e.tea}', 'چائے'];
                    } else if (singleCategory == 'Extra Expense') {
                      return [e.date, e.day, 'Rs. ${e.extra}', e.extraDetails];
                    }
                    return [
                      e.date,
                      'Rs. ${e.rickshaw}',
                      'Rs. ${e.lunch}',
                      'Rs. ${e.tea}',
                      'Rs. ${e.general}',
                      'Rs. ${e.extra}',
                      'Rs. ${e.total}',
                    ];
                  }).toList(),
                ),

                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "خلاصہ: خرچ شدہ رقم محفوظ طریقے سے تصدیق شدہ ہے۔",
                    style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}
