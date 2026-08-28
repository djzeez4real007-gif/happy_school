import 'package:flutter/material.dart';
import '../../widgets/announcement_marquee.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../services/auth_service.dart';
import '../../services/student_fee_payment_storage.dart';
import '../fees/fees_dashboard_screen.dart';
import '../fees/debtors_list_screen.dart';
import '../fees/student_fee_payment_screen.dart';
import '../fees/financial_reports_screen.dart';

class AccountantDashboardScreen extends StatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  State<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState extends State<AccountantDashboardScreen> {
  bool loading = true;
  String session = Sessions.current();
  double collectedSession = 0;
  double collectedToday = 0;
  int receiptsToday = 0;
  int receiptsSession = 0;

  @override
  void initState() {
    super.initState();
    if (!Sessions.list().contains(session) && Sessions.list().isNotEmpty) {
      session = Sessions.list().first;
    }
    _load();
  }

  bool _isToday(String raw) {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final s = raw.trim();
    if (s.startsWith(key)) return true;
    try {
      final d = DateTime.tryParse(s);
      if (d == null) return false;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    double sess = 0, today = 0;
    int rToday = 0, rSess = 0;
    try {
      final payments = await StudentFeePaymentStorage.getPayments();
      for (final p in payments) {
        if (p.session.trim() != session.trim()) continue;
        sess += p.amountPaid;
        rSess++;
        if (_isToday(p.paymentDate)) {
          today += p.amountPaid;
          rToday++;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      collectedSession = sess;
      collectedToday = today;
      receiptsToday = rToday;
      receiptsSession = rSess;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final name = AuthService.currentName;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accounts',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          name.isEmpty ? 'Accountant' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Session $session',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const AnnouncementMarquee(),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: Sessions.list().contains(session) ? session : null,
                    decoration: const InputDecoration(
                      labelText: 'Session',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: Sessions.list()
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => session = v);
                      _load();
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          'Collected today',
                          '₦${fmt.format(collectedToday)}',
                          '$receiptsToday receipt(s)',
                          const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _stat(
                          'Session total',
                          '₦${fmt.format(collectedSession)}',
                          '$receiptsSession receipt(s)',
                          const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Quick actions',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _link(Icons.point_of_sale_rounded, 'Receive payment',
                      'Record a student payment', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentFeePaymentScreen(),
                      ),
                    );
                  }),
                  _link(Icons.people_outline_rounded, 'Debtors list',
                      'Students still owing', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DebtorsListScreen(),
                      ),
                    );
                  }),
                  _link(Icons.dashboard_rounded, 'Fees dashboard',
                      'Full fees overview', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FeesDashboardScreen(),
                      ),
                    );
                  }),
                  _link(Icons.assessment_rounded, 'Financial reports',
                      'Session / term summaries', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FinancialReportsScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _stat(String title, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          Text(sub,
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _link(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF059669)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
