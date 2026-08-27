import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/student_fee_payment_storage.dart';

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  bool loading = true;
  List payments = [];
  double total = 0;

  String get admissionNo => AuthService.currentUser?.username ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list =
        await StudentFeePaymentStorage.getStudentPayments(admissionNo);
    list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final sum = await StudentFeePaymentStorage.totalPaid(admissionNo);
    if (!mounted) return;
    setState(() {
      payments = list;
      total = sum;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('My fees'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Total paid: ₦${fmt.format(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (payments.isEmpty)
                  const Text('No payments recorded yet.')
                else
                  ...payments.map((p) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          '₦${fmt.format(p.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${p.session} · ${p.term}\n${p.date}${p.method != null && p.method.toString().isNotEmpty ? ' · ${p.method}' : ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
