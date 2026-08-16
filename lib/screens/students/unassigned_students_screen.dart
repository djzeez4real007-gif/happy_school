import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';
import 'student_class_assignment_screen.dart';

class UnassignedStudentsScreen extends StatefulWidget {
  const UnassignedStudentsScreen({super.key});

  @override
  State<UnassignedStudentsScreen> createState() =>
      _UnassignedStudentsScreenState();
}

class _UnassignedStudentsScreenState extends State<UnassignedStudentsScreen> {
  List<Student> unassigned = [];
  bool loading = true;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    final allStudents = await StudentStorage.getStudents();
    final assignments = await StudentClassStorage.getStudents();

    final assignedNos = assignments
        .map((a) => a.admissionNo.trim().toLowerCase())
        .toSet();

    final list = allStudents.where((s) {
      return !assignedNos.contains(s.admissionNo.trim().toLowerCase());
    }).toList();

    list.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );

    if (!mounted) return;
    setState(() {
      unassigned = list;
      loading = false;
    });
  }

  Future<void> assign(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentClassAssignmentScreen(),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Unassigned (${unassigned.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : unassigned.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 56,
                          color: Colors.green.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'All students are assigned',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Every registered student is in a class',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.orange.shade800),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'These students are registered but not placed in any class yet.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: unassigned.length,
                        itemBuilder: (context, index) {
                          final student = unassigned[index];
                          final initial = student.fullName.isNotEmpty
                              ? student.fullName[0].toUpperCase()
                              : '?';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.035),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          student.admissionNo,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () => assign(student),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Assign'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
