import 'dart:convert';

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

  String get admissionNo {
    final u = AuthService.currentUser;
    if (u == null) return '';
    if (u.childrenAdmissionNos.isNotEmpty) return u.childrenAdmissionNos.first;
    return u.username;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final adm = admissionNo;
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

  ImageProvider? _passport(Student s) {
    final p = s.passport.trim();
    if (p.isEmpty) return null;
    try {
      if (p.startsWith('data:')) {
        final b64 = p.split(',').last;
        return MemoryImage(base64Decode(b64));
      }
      if (p.startsWith('http')) return NetworkImage(p);
      // raw base64
      return MemoryImage(base64Decode(p));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = student;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('My profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : s == null
              ? Center(child: Text('Profile not found'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Header bio card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 88,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white38),
                              image: _passport(s) != null
                                  ? DecorationImage(
                                      image: _passport(s)!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _passport(s) == null
                                ? const Icon(Icons.person,
                                    color: Colors.white70, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.admissionNo,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.gender,
                                  style: const TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Personal information'),
                    _card([
                      _row('Date of birth', s.dateOfBirth),
                      _row('Nationality', s.nationality),
                      _row('Religion', s.religion),
                      _row('State', s.state),
                      _row('LGA', s.localGovernment),
                      _row('Address', s.address),
                    ]),
                    const SizedBox(height: 14),
                    _sectionTitle('Guardian / contact'),
                    _card([
                      _row('Parent / guardian', s.parentName),
                      _row('Phone', s.phone),
                      _row('Email', s.email),
                    ]),
                    const SizedBox(height: 14),
                    _sectionTitle('Medical'),
                    _card([
                      _row('Blood group', s.bloodGroup),
                      _row('Genotype', s.genotype),
                      _row('Medical condition', s.medicalCondition),
                    ]),
                  ],
                ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        t,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: AppColors.textSecondary(context),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, color: AppColors.cardBorder(context)),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              (v.trim().isEmpty) ? '—' : v,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
