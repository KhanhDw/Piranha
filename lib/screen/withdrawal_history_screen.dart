import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  _WithdrawalHistoryScreen createState() => _WithdrawalHistoryScreen();
}

class Withdrawal {
  final double amount;
  final DateTime date;
  final bool success;

  Withdrawal({required this.amount, required this.date, required this.success});
}

class _WithdrawalHistoryScreen extends State<WithdrawalHistoryScreen> {
  @override
  void initState() {
    super.initState();
  }

  final List<Withdrawal> history = [
    Withdrawal(amount: 500000, date: DateTime(2025, 4, 1), success: true),
    Withdrawal(amount: 300000, date: DateTime(2025, 3, 28), success: false),
    Withdrawal(amount: 200000, date: DateTime(2025, 3, 25), success: true),
  ];

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lịch sử rút tiền'),
          backgroundColor: Colors.teal,
        ),
        body: ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  item.success ? Icons.check_circle : Icons.cancel,
                  color: item.success ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(item.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Ngày: ${formatDate(item.date)}'),
                trailing: Text(
                  item.success ? 'Thành công' : 'Thất bại',
                  style: TextStyle(
                    color: item.success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
