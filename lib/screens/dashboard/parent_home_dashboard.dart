
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/student_storage.dart';
import '../../services/student_fee_payment_storage.dart';

/// Parent home: list linked children and fee paid summary.
class ParentHomeDashboard extends StatefulWidget {
  const ParentHomeDashboard({super.key});

  @override
  State<ParentHomeDashboard> createState() => _ParentHomeDashboardState();
}

class _ParentHomeDashboardState extends State<ParentHomeDashboard> {
  bool loading = true;
  List<Map<String, String>> children = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final nos = AuthService.currentUser?.childrenAdmissionNos ?? [];
    final out = <Map<String, String>>[];
    try {
      final students = await StudentStorage.getStudents();
      for (final adm in nos) {
        final match = students.where(
          (s) => s.admissionNo.trim().toLowerCase() == adm.trim().toLowerCase(),
        );
        final name = match.isEmpty ? adm : match.first.fullName;
        double paid = 0;
        try {
          paid = await StudentFeePaymentStorage.totalPaid(adm);
        } catch (_) {}
        out.add({
          'admissionNo': adm,
          'name': name,
          'paid': paid.toStringAsFixed(0),
        });
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      children = out;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Parent portal',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          name.isEmpty ? 'Parent' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${children.length} linked child(ren)',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (children.isEmpty)
                    const Text(
                      'No children linked to this account.\nAsk admin to link admission numbers on your user profile.',
                    )
                  else
                    ...children.map((c) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF7C3AED),
                            child: Icon(Icons.child_care, color: Colors.white),
                          ),
                          title: Text(
                            c['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            'Admission: ${c['admissionNo']}\nFees paid (recorded): ₦${c['paid']}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
