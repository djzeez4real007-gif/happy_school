import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../core/utils/sessions.dart';
import '../../core/theme/app_colors.dart';

import '../../core/widgets/premium_feedback.dart';

import '../../models/student.dart';
import '../../models/school_class.dart';
import '../../models/student_class.dart';
import '../../models/student_subject.dart';

import '../../services/audit_log_storage.dart';
import '../../services/student_storage.dart';
import '../../services/class_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_subject_storage.dart';
import '../../services/class_subject_storage.dart';

class StudentClassAssignmentScreen extends StatefulWidget {
  final StudentClass? studentClass;
  final int? index;
  /// When opening from Unassigned list, lock this student.
  final Student? preselectedStudent;

  const StudentClassAssignmentScreen({
    super.key,
    this.studentClass,
    this.index,
    this.preselectedStudent,
  });

  @override
  State<StudentClassAssignmentScreen> createState() =>
      _StudentClassAssignmentScreenState();
}

class _StudentClassAssignmentScreenState
    extends State<StudentClassAssignmentScreen> {
  List<Student> students = [];
  List<SchoolClass> classes = [];

  Student? selectedStudent;
  SchoolClass? selectedClass;
  String selectedSession = '2026/2027';
  String studentSearch = '';
  bool saving = false;
  bool loading = true;

  final List<String> sessions = Sessions.list();

  List<Student> get filteredStudents {
    final q = studentSearch.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            s.admissionNo.toLowerCase().contains(q))
        .toList();
  }

  static const Color _bg = Color(0xFFF5F7FB);
  Color get _primary => AppColors.primary;

  bool get isEdit => widget.studentClass != null;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    students = await StudentStorage.getStudents();
    classes = await ClassStorage.getClasses();

    if (widget.studentClass != null) {
      try {
        selectedStudent = students.firstWhere(
          (e) => e.admissionNo == widget.studentClass!.admissionNo,
        );
      } catch (_) {}

      try {
        selectedClass = classes.firstWhere(
          (e) => e.fullClassName == widget.studentClass!.className,
        );
      } catch (_) {}

      if (widget.studentClass!.session.isNotEmpty) {
        selectedSession = widget.studentClass!.session;
      }
    } else if (widget.preselectedStudent != null) {
      try {
        selectedStudent = students.firstWhere(
          (e) =>
              e.admissionNo.trim().toLowerCase() ==
              widget.preselectedStudent!.admissionNo.trim().toLowerCase(),
        );
      } catch (_) {
        selectedStudent = widget.preselectedStudent;
      }
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> saveAssignment() async {
    if (selectedStudent == null || selectedClass == null) {
      PremiumFeedback.info(
        context,
        title: 'Select student and class',
        subtitle: 'Both fields are required',
      );
      return;
    }

    setState(() => saving = true);

    try {
      final item = StudentClass(
        admissionNo: selectedStudent!.admissionNo,
        studentName: selectedStudent!.fullName,
        className: selectedClass!.fullClassName,
        session: selectedSession,
        term: '',
      );

      if (widget.studentClass == null) {
        await StudentClassStorage.assignStudent(item);
      } else {
        await StudentClassStorage.updateStudent(widget.index!, item);
      }

      await StudentSubjectStorage.deleteSubjects(selectedStudent!.admissionNo);

      final classSubjects = await ClassSubjectStorage.getClassSubjects(
        selectedClass!.fullClassName,
      );

      for (final subject in classSubjects) {
        await StudentSubjectStorage.assignSubject(
          StudentSubject(
            admissionNo: selectedStudent!.admissionNo,
            studentName: selectedStudent!.fullName,
            className: selectedClass!.fullClassName,
            subjectCode: subject.subjectCode,
            subjectName: subject.subjectName,
            session: selectedSession,
            term: '',
          ),
        );
      }

      if (!mounted) return;

      await AuditLogStorage.log(
        action: isEdit ? 'class_assignment_updated' : 'class_assigned',
        module: 'students',
        description: isEdit
            ? 'Updated class assignment for ${selectedStudent?.fullName ?? ""}'
            : 'Assigned ${selectedStudent?.fullName ?? ""} to ${selectedClass?.fullClassName ?? ""}',
        refId: selectedStudent?.admissionNo,
      );
      PremiumFeedback.success(
        context,
        title: isEdit ? 'Assignment updated' : 'Student assigned successfully',
        subtitle: isEdit
            ? 'Class placement has been saved'
            : 'Student placed in class for this session',
        icon: Icons.school_rounded,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(
        context,
        title: 'Assignment failed',
        subtitle: '$e',
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: AppBack.leading(context),
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Assignment' : 'Assign to Class',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Placement',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Session-based assignment (no term needed)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: sessions.contains(selectedSession)
                            ? selectedSession
                            : null,
                        decoration: _fieldDecoration(
                          label: 'Academic Session',
                          icon: Icons.calendar_today_rounded,
                        ),
                        items: sessions
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedSession = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SchoolClass>(
                        value: selectedClass,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          label: 'Class',
                          icon: Icons.class_rounded,
                        ),
                        items: classes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.fullClassName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedClass = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isEdit)
                        InputDecorator(
                          decoration: _fieldDecoration(
                            label: 'Student',
                            icon: Icons.person_rounded,
                          ),
                          child: Text(
                            selectedStudent == null
                                ? '—'
                                : '${selectedStudent!.admissionNo} — ${selectedStudent!.fullName}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      else ...[
                        TextField(
                          decoration: _fieldDecoration(
                            label: 'Search student',
                            icon: Icons.search_rounded,
                          ).copyWith(
                            hintText: 'Type name or admission number…',
                          ),
                          onChanged: (v) => setState(() {
                            studentSearch = v;
                            if (selectedStudent != null) {
                              final stillVisible = filteredStudents.any(
                                (s) =>
                                    s.admissionNo == selectedStudent!.admissionNo,
                              );
                              if (!stillVisible) selectedStudent = null;
                            }
                          }),
                        ),
                        const SizedBox(height: 10),
                        if (selectedStudent != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle, color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${selectedStudent!.admissionNo} — ${selectedStudent!.fullName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(
                                    () => selectedStudent = null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (selectedStudent != null) const SizedBox(height: 8),
                        if (studentSearch.trim().isNotEmpty &&
                            selectedStudent == null)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: filteredStudents.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Text(
                                      'No student matches',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filteredStudents.length,
                                    separatorBuilder: (_, __) =>
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                    itemBuilder: (context, index) {
                                      final s = filteredStudents[index];
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              AppColors.primary,
                                          child: Text(
                                            s.firstName.isNotEmpty
                                                ? s.firstName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          s.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          s.admissionNo,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            selectedStudent = s;
                                            studentSearch = s.fullName;
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        if (studentSearch.trim().isEmpty &&
                            selectedStudent == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Start typing to see matching students',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),

                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : saveAssignment,
                    icon: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isEdit ? Icons.save_rounded : Icons.check_rounded),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : (isEdit ? 'UPDATE ASSIGNMENT' : 'ASSIGN STUDENT'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}