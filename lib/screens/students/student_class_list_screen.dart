import 'package:flutter/material.dart';

import '../../models/student_class.dart';
import '../../services/student_class_storage.dart';
import '../promotion/student_promotion_screen.dart';
import 'student_class_assignment_screen.dart';

class StudentClassListScreen extends StatefulWidget {
  const StudentClassListScreen({super.key});

  @override
  State<StudentClassListScreen> createState() => _StudentClassListScreenState();
}

class _StudentClassListScreenState extends State<StudentClassListScreen> {
  List<StudentClass> students = [];
  List<StudentClass> filteredStudents = [];
  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() => loading = true);
    final data = await StudentClassStorage.getStudents();

    if (!mounted) return;

    setState(() {
      students = data;
      filteredStudents = List<StudentClass>.from(data);
      loading = false;
    });
  }

  void searchStudent(String value) {
    final query = value.trim().toLowerCase();

    final results = query.isEmpty
        ? List<StudentClass>.from(students)
        : students.where((student) {
            return student.studentName.toLowerCase().contains(query) ||
                student.admissionNo.toLowerCase().contains(query) ||
                student.className.toLowerCase().contains(query) ||
                student.session.toLowerCase().contains(query);
          }).toList();

    if (!mounted) return;
    setState(() => filteredStudents = results);
  }

  Future<void> openAddAssignment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentClassAssignmentScreen()),
    );
    if (!mounted) return;
    await loadStudents();
  }

  Future<void> openPromotion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentPromotionScreen()),
    );
    if (!mounted) return;
    await loadStudents();
  }

  Future<void> editAssignment(StudentClass student, int realIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentClassAssignmentScreen(
          studentClass: student,
          index: realIndex,
        ),
      ),
    );
    if (!mounted) return;
    await loadStudents();
  }

  Future<void> deleteAssignment(StudentClass student, int realIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Assignment'),
          content: Text(
            'Remove class assignment for ${student.studentName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await StudentClassStorage.deleteStudent(realIndex);
    if (!mounted) return;
    await loadStudents();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Assignment deleted'),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
          'Assigned (${filteredStudents.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Promote Students',
            icon: const Icon(Icons.upgrade_rounded),
            onPressed: openPromotion,
          ),
          IconButton(
            tooltip: 'Add Assignment',
            icon: const Icon(Icons.add_rounded),
            onPressed: openAddAssignment,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddAssignment,
        backgroundColor: _primary,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Assign'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: searchStudent,
                decoration: InputDecoration(
                  hintText: 'Search name, admission, class, session...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchController.clear();
                            searchStudent('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.class_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No assignments found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];

                          final realIndex = students.indexWhere(
                            (item) =>
                                item.admissionNo == student.admissionNo &&
                                item.className == student.className &&
                                item.session == student.session,
                          );

                          final initial = student.studentName.isNotEmpty
                              ? student.studentName[0].toUpperCase()
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
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1D4ED8),
                                          Color(0xFF3B82F6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                          student.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
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
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _chip(
                                              student.className,
                                              const Color(0xFFEFF6FF),
                                              const Color(0xFF1D4ED8),
                                            ),
                                            _chip(
                                              student.session,
                                              const Color(0xFFF0FDF4),
                                              const Color(0xFF15803D),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (realIndex == -1) return;
                                      if (value == 'edit') {
                                        await editAssignment(
                                            student, realIndex);
                                      }
                                      if (value == 'promote') {
                                        await openPromotion();
                                      }
                                      if (value == 'delete') {
                                        await deleteAssignment(
                                            student, realIndex);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'promote',
                                        child: Text('Promote'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
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

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
