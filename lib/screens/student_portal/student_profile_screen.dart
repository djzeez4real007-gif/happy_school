import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student.dart';
import '../../services/auth_service.dart';
import '../../services/student_storage.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Student? student;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final adm = AuthService.currentUser?.username ?? '';
    final all = await StudentStorage.getStudents();
    Student? s;
    for (final x in all) {
      if (x.admissionNo.trim().toLowerCase() == adm.trim().toLowerCase()) {
        s = x;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      student = s;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = student;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('My profile'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? const Center(child: Text('Profile not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _row('Admission no.', s.admissionNo),
                    _row('Full name', s.fullName),
                    _row('Gender', s.gender),
                    _row('Date of birth', s.dateOfBirth),
                    _row('Parent / guardian', s.parentName),
                    _row('Phone', s.phone),
                    _row('Email', s.email),
                    _row('Address', s.address),
                    _row('State', s.state),
                    _row('LGA', s.localGovernment),
                  ],
                ),
    );
  }

  Widget _row(String k, String v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? '—' : v,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
