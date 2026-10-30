import 'package:telephony/telephony.dart';
import '../models/expense_model.dart';
import 'db_helper.dart';
import 'package:intl/intl.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  void initSmsListener(Function(Expense) onSmsDetected) async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          parseAndSaveSms(message, onSmsDetected);
        },
        listenInBackground: false,
      );
    }
  }

  void parseAndSaveSms(SmsMessage message, Function(Expense) onSmsDetected) async {
    final body = message.body ?? '';
    final address = message.address?.toLowerCase() ?? '';

    // Regex to detect debits from Pakistani banks/wallets (JazzCash, Easypaisa, SadaPay, HBL, Meezan)
    final debitPattern = RegExp(r'(paid|debited|spent|transferred|sent Rs\.?|Rs\.?|PKR)\s*([0-9,]+(\.[0-9]+)?)', caseSensitive: false);
    final match = debitPattern.firstMatch(body);

    if (match != null) {
      String amountStr = match.group(2)!.replaceAll(',', '');
      double amount = double.tryParse(amountStr) ?? 0.0;

      if (amount > 0) {
        String paymentSource = 'Digital';
        if (address.contains('jazzcash') || body.toLowerCase().contains('jazzcash')) {
          paymentSource = 'JazzCash';
        } else if (address.contains('easypaisa') || body.toLowerCase().contains('easypaisa')) {
          paymentSource = 'EasyPaisa';
        } else if (address.contains('sadapay') || address.contains('nayapay')) {
          paymentSource = 'Wallet';
        } else {
          paymentSource = 'Bank SMS';
        }

        final now = DateTime.now();
        final expense = Expense(
          date: DateFormat('yyyy-MM-dd').format(now),
          day: DateFormat('EEEE').format(now),
          extra: amount,
          extraDetails: 'آٹو ایس ایم ایس: ${message.address ?? "Bank"} ($paymentSource)',
          paymentMode: paymentSource,
        );

        await DatabaseHelper.instance.insertExpense(expense);
        onSmsDetected(expense);
      }
    }
  }
}
