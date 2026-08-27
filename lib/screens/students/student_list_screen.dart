import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../models/student.dart';
import '../../models/student_class.dart';

import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';

import 'student_details_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Student> students = [];
  List<Student> filteredStudents = [];
  List<StudentClass> assignedStudents = [];
  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() => loading = true);
    try {
      students = await StudentStorage.getStudents();
    } catch (_) {
      students = [];
    }
    try {
      assignedStudents = await StudentClassStorage.getStudents();
    } catch (_) {
      assignedStudents = [];
    }

    if (!mounted) return;
    setState(() {
      filteredStudents = students;
      loading = false;
    });
  }

  String classFor(Student student) {
    final assignment = assignedStudents.where(
      (e) => e.admissionNo.trim().toLowerCase() ==
          student.admissionNo.trim().toLowerCase(),
    );
    if (assignment.isEmpty) return 'Not Assigned';
    // Prefer latest session
    final list = assignment.toList()
      ..sort((a, b) => b.session.compareTo(a.session));
    return list.first.className;
  }

  void searchStudent(String value) {
    final keyword = value.toLowerCase().trim();
    setState(() {
      if (keyword.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students.where((student) {
          final className = classFor(student);
          return student.admissionNo.toLowerCase().contains(keyword) ||
              student.surname.toLowerCase().contains(keyword) ||
              student.firstName.toLowerCase().contains(keyword) ||
              student.fullName.toLowerCase().contains(keyword) ||
              student.phone.toLowerCase().contains(keyword) ||
              className.toLowerCase().contains(keyword);
        }).toList();
      }
    });
  }

  Widget buildStudentCard(Student student, int index) {
    final className = classFor(student);
    final assigned = className != 'Not Assigned';
    final initial = student.firstName.isNotEmpty
        ? student.firstName[0].toUpperCase()
        : (student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?');

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StudentDetailsScreen(student: student, index: index),
              ),
            );
            await loadStudents();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: assigned
                          ? [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]
                          : [Colors.orange.shade400, Colors.orange.shade600],
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.admissionNo,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: assigned
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          className,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: assigned
                                ? const Color(0xFF1D4ED8)
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Students (${filteredStudents.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search bar
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
                  hintText: 'Search name, admission no, class...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
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
                            Icon(Icons.people_outline,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No student found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: filteredStudents.length,
                        itemBuilder: (_, index) {
                          return buildStudentCard(
                            filteredStudents[index],
                            index,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
