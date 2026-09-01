import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_storage.dart';
import 'student_class_assignment_screen.dart';

class UnassignedStudentsScreen extends StatefulWidget {
  const UnassignedStudentsScreen({super.key});

  @override
  State<UnassignedStudentsScreen> createState() =>
      _UnassignedStudentsScreenState();
}

class _UnassignedStudentsScreenState extends State<UnassignedStudentsScreen> {
  bool loading = true;
  List<Student> unassigned = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final students = await StudentStorage.getStudents();
    final assignments = await StudentClassStorage.getStudents();
    final assigned = assignments
        .map((a) => a.admissionNo.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toSet();

    final list = students
        .where((s) => !assigned.contains(s.admissionNo.trim().toLowerCase()))
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    if (!mounted) return;
    setState(() {
      unassigned = list;
      loading = false;
    });
  }

  Future<void> _assign(Student student) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentClassAssignmentScreen(
          preselectedStudent: student,
        ),
      ),
    );
    await _load();
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.fullName} assigned')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text('Unassigned (${unassigned.length})'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFC2410C)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These students are registered but not placed in any class yet.',
                          style: TextStyle(
                            color: Color(0xFFC2410C),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (unassigned.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('All registered students have a class.'),
                    ),
                  )
                else
                  ...unassigned.map((s) {
                    final initial =
                        s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFFEA580C).withValues(alpha: 0.15),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFFEA580C),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          s.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(s.admissionNo),
                        trailing: FilledButton(
                          onPressed: () => _assign(s),
                          child: const Text('Assign'),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
