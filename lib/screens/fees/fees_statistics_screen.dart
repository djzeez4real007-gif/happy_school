import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../services/fees_dashboard_service.dart';
import '../../widgets/dashboard_progress_card.dart';
import '../../models/student_fee_payment.dart';
import '../../services/student_fee_payment_storage.dart';

class FeesStatisticsScreen extends StatefulWidget {
  const FeesStatisticsScreen({super.key});

  @override
  State<FeesStatisticsScreen> createState() => _FeesStatisticsScreenState();
}

class _FeesStatisticsScreenState extends State<FeesStatisticsScreen> {
  bool loading = true;

  List<StudentFeePayment> recentPayments = [];

  double totalCollected = 0;
  double totalOutstanding = 0;

  int totalPayments = 0;
  int studentsPaid = 0;
  int debtors = 0;

  double collectionPercentage = 0;

  double todayCollection = 0;

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    totalCollected = await FeesDashboardService.totalFeesCollected();

    totalOutstanding = await FeesDashboardService.totalOutstanding();

    totalPayments = await FeesDashboardService.totalPayments();

    studentsPaid = await FeesDashboardService.totalStudentsPaid();

    debtors = await FeesDashboardService.totalDebtors();

    collectionPercentage = await FeesDashboardService.collectionPercentage();

    todayCollection = await FeesDashboardService.todayCollection();

    recentPayments = await StudentFeePaymentStorage.getPayments();

    recentPayments = recentPayments.reversed.take(5).toList();

    loading = false;

    if (mounted) {
      setState(() {});
    }
  }

  String money(double value) {
    return value.toStringAsFixed(2);
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: .15),
              child: Icon(icon, color: color, size: 30),
            ),

            const SizedBox(height: 15),

            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),

            const SizedBox(height: 8),

            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: const Text("Fees Dashboard")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      statCard(
                        title: "Total Collected",
                        value: "NGN ${money(totalCollected)}",
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                      ),

                      statCard(
                        title: "Today's Collection",
                        value: "NGN ${money(todayCollection)}",
                        icon: Icons.today,
                        color: Colors.teal,
                      ),

                      statCard(
                        title: "Outstanding",
                        value: "NGN ${money(totalOutstanding)}",
                        icon: Icons.warning,
                        color: Colors.red,
                      ),

                      statCard(
                        title: "Payments",
                        value: totalPayments.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),

                      statCard(
                        title: "Students Paid",
                        value: studentsPaid.toString(),
                        icon: Icons.people,
                        color: Colors.orange,
                      ),

                      statCard(
                        title: "Debtors",
                        value: debtors.toString(),
                        icon: Icons.person_off,
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  DashboardProgressCard(
                    title: "Collection Progress",
                    value: collectionPercentage,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Quick Summary",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      title: const Text("Fees Collected"),
                      subtitle: Text("NGN ${money(totalCollected)}"),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.money_off, color: Colors.red),
                      title: const Text("Outstanding Fees"),
                      subtitle: Text("NGN ${money(totalOutstanding)}"),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.people, color: Colors.blue),
                      title: const Text("Students Paid"),
                      subtitle: Text(studentsPaid.toString()),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_off,
                        color: Colors.orange,
                      ),
                      title: const Text("Debtors"),
                      subtitle: Text(debtors.toString()),
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    "Recent Payments",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),

                  const SizedBox(height: 12),

                  ...recentPayments.map<Widget>((payment) {
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long),
                        ),
                        title: Text(payment.studentName),
                        subtitle: Text(
                          "${payment.receiptNo}\n${payment.paymentDate}",
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          "NGN ${money(payment.amountPaid)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
