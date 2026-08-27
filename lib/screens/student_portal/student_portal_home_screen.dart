import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student.dart';
import '../../services/auth_service.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/student_storage.dart';
import 'student_fees_screen.dart';
import 'student_profile_screen.dart';
import 'student_results_screen.dart';

class StudentPortalHomeScreen extends StatefulWidget {
  const StudentPortalHomeScreen({super.key});

  @override
  State<StudentPortalHomeScreen> createState() =>
      _StudentPortalHomeScreenState();
}

class _StudentPortalHomeScreenState extends State<StudentPortalHomeScreen> {
  bool loading = true;
  Student? student;
  String className = '—';
  double totalPaid = 0;

  String get admissionNo {
    final u = AuthService.currentUser;
    if (u == null) return '';
    final linked = u.childrenAdmissionNos;
    if (linked.isNotEmpty) return linked.first;
    return u.username;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final adm = admissionNo;

    Student? s;
    try {
      final all = await StudentStorage.getStudents();
      for (final x in all) {
        if (x.admissionNo.trim().toLowerCase() == adm.trim().toLowerCase()) {
          s = x;
          break;
        }
      }
    } catch (_) {}

    String cls = '—';
    try {
      final history =
          await StudentClassStorage.getStudentHistory(adm);
      if (history.isNotEmpty) {
        history.sort((a, b) => b.session.compareTo(a.session));
        cls = history.first.className;
      } else {
        final one = await StudentClassStorage.getStudent(adm);
        if (one != null) cls = one.className;
      }
    } catch (_) {}

    double paid = 0;
    try {
      paid = await StudentFeePaymentStorage.totalPaid(adm);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      student = s;
      className = cls;
      totalPaid = paid;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = student?.fullName ?? AuthService.currentName;

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
                        colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student portal',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.isEmpty ? 'Student' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Admission: $admissionNo',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Class: $className',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded,
                            color: Color(0xFF2563EB)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total fees paid (recorded): ₦${NumberFormat('#,##0').format(totalPaid)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Quick links',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _link(
                    Icons.assessment_rounded,
                    'My results',
                    'Session & term scores',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentResultsScreen(),
                      ),
                    ),
                  ),
                  _link(
                    Icons.payments_rounded,
                    'My fees',
                    'Payments and balance',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentFeesScreen(),
                      ),
                    ),
                  ),
                  _link(
                    Icons.person_rounded,
                    'My profile',
                    'Personal details',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _link(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
          child: Icon(icon, color: const Color(0xFF2563EB)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
