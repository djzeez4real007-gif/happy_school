import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../models/student.dart';
import '../../services/student_portal_storage.dart';
import '../../services/student_storage.dart';

/// Admin/Principal: generate or reset student portal passwords.
class StudentPortalAdminScreen extends StatefulWidget {
  const StudentPortalAdminScreen({super.key});

  @override
  State<StudentPortalAdminScreen> createState() =>
      _StudentPortalAdminScreenState();
}

class _StudentPortalAdminScreenState extends State<StudentPortalAdminScreen> {
  bool loading = true;
  List<Student> students = [];
  String query = '';
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await StudentStorage.getStudents();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    if (!mounted) return;
    setState(() {
      students = list;
      loading = false;
    });
  }

  Future<void> _generate(Student s) async {
    final plain = await StudentPortalStorage.setPassword(
      admissionNo: s.admissionNo,
      fullName: s.fullName,
    );
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Portal password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${s.fullName}'),
            Text('Login (admission no.): ${s.admissionNo}'),
            const SizedBox(height: 12),
            SelectableText(
              plain,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Copy this password now. It will not be shown again.',
              style: TextStyle(color: Colors.red, fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: plain));
              Navigator.pop(ctx);
              PremiumFeedback.success(context,
                  title: 'Copied', subtitle: 'Password copied to clipboard');
            },
            child: const Text('Copy & close'),
          ),
        ],
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = students.where((s) {
      if (q.isEmpty) return true;
      return s.fullName.toLowerCase().contains(q) ||
          s.admissionNo.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Student portal access'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search name or admission no…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Login = admission number. Generate a password and give it to the student/parent.',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return FutureBuilder<bool>(
                        future: StudentPortalStorage.hasAccount(s.admissionNo),
                        builder: (context, snap) {
                          final has = snap.data == true;
                          return ListTile(
                            title: Text(
                              s.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              '${s.admissionNo}${has ? ' · Portal enabled' : ' · No password yet'}',
                            ),
                            trailing: TextButton(
                              onPressed: () => _generate(s),
                              child: Text(has ? 'Reset password' : 'Generate'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
