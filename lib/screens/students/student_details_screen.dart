import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';
import 'student_registration_screen.dart';
import 'student_id_card_preview_screen.dart';
import '../../services/student_promotion_storage.dart';
import '../../services/student_status_service.dart';
import '../../models/student_promotion.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;
  final int index;

  const StudentDetailsScreen({
    super.key,
    required this.student,
    required this.index,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  StudentClass? studentClass;
  List<StudentClass> classHistory = [];
  List<StudentPromotion> promotionHistory = [];
  bool isGraduated = false;
  String? graduationSession;
  bool hasLeft = false;
  String? leftSession;

  @override
  void initState() {
    super.initState();
    loadClass();
  }

  Future<void> loadClass() async {
    // Get all assignments for this student and pick the latest session
    final history = await StudentClassStorage.getStudentHistory(
      widget.student.admissionNo,
    );

    StudentClass? result;

    if (history.isNotEmpty) {
      // Sort by session descending so newest comes first
      // e.g. 2027/2028 > 2026/2027 > 2025/2026
      history.sort((a, b) => b.session.compareTo(a.session));
      result = history.first;
    }

    final promotions = await StudentPromotionStorage.getPromotions();
    final mine = promotions
        .where((p) =>
            p.admissionNo.trim().toLowerCase() ==
            widget.student.admissionNo.trim().toLowerCase())
        .toList();
    mine.sort((a, b) => b.toSession.compareTo(a.toSession));

    final grad = await StudentStatusService.graduationRecord(
      widget.student.admissionNo,
    );
    final left = await StudentStatusService.leftRecord(
      widget.student.admissionNo,
    );

    if (!mounted) return;

    setState(() {
      studentClass = result;
      classHistory = history;
      promotionHistory = mine;
      isGraduated = grad != null;
      graduationSession = grad?.session;
      hasLeft = left != null;
      leftSession = left?.session;
    });
  }

  Widget buildTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? "Not Available" : value),
      ),
    );
  }

  Future<void> editStudent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentRegistrationScreen(
          student: widget.student,
          index: widget.index,
        ),
      ),
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> deleteStudent() async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (delete != true) return;

    await StudentStorage.deleteStudent(widget.index);
    await AuditLogStorage.log(
      action: 'student_deleted',
      module: 'students',
      description: 'Deleted student ${widget.student.fullName}',
      refId: widget.student.admissionNo,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student deleted successfully")),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: "Print ID Card",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentIdCardPreviewScreen(
                    student: widget.student,
                    studentClass: studentClass,
                    session: studentClass?.session.isNotEmpty == true
                        ? studentClass!.session
                        : '2026/2027',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Student",
            onPressed: editStudent,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Delete Student",
            onPressed: deleteStudent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundImage: student.passport.isNotEmpty
                  ? FileImage(File(student.passport))
                  : null,
              child: student.passport.isEmpty
                  ? Text(
                      student.firstName.isNotEmpty
                          ? student.firstName[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            Text(
              student.fullName,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            buildTile(Icons.badge, "Admission Number", student.admissionNo),

            buildTile(Icons.person, "Surname", student.surname),

            buildTile(Icons.person_outline, "First Name", student.firstName),

            buildTile(
              Icons.person_2_outlined,
              "Middle Name",
              student.middleName,
            ),

            buildTile(Icons.wc, "Gender", student.gender),

            buildTile(Icons.cake, "Date of Birth", student.dateOfBirth),

            buildTile(
              Icons.school,
              "Class",
              studentClass?.className ?? "Not Assigned Yet",
            ),

            buildTile(
              Icons.calendar_month,
              "Session",
              studentClass?.session ?? "Not Assigned Yet",
            ),

            if (isGraduated)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFFD1FAE5),
                child: ListTile(
                  leading: const Icon(Icons.school, color: Color(0xFF059669)),
                  title: const Text(
                    'Status: GRADUATED',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF059669),
                    ),
                  ),
                  subtitle: Text(
                    graduationSession == null
                        ? 'Alumni — completed SS3'
                        : 'Graduation session: $graduationSession',
                  ),
                ),
              ),

            if (hasLeft)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFFF1F5F9),
                child: ListTile(
                  leading: const Icon(Icons.person_off_outlined, color: Color(0xFF64748B)),
                  title: const Text(
                    'Status: LEFT SCHOOL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  subtitle: Text(
                    leftSession == null
                        ? 'Did not return for the next class'
                        : 'Recorded for session: $leftSession',
                  ),
                ),
              ),

            // Term removed — class assignment is session-based only.

            if (promotionHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Promotion / Repeat history',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              ...promotionHistory.map((p) {
                final repeated = p.outcome == 'repeated';
                final graduated = p.outcome == 'graduated' ||
                    p.toClass.trim().toLowerCase() == 'graduated';
                final leftSchool = p.outcome == 'left' ||
                    p.toClass.trim().toLowerCase() == 'left';
                final title = graduated
                    ? 'GRADUATED'
                    : leftSchool
                        ? 'LEFT SCHOOL'
                        : repeated
                            ? 'REPEATED'
                            : 'PROMOTED';
                final color = graduated
                    ? const Color(0xFF059669)
                    : leftSchool
                        ? const Color(0xFF64748B)
                        : repeated
                            ? const Color(0xFFD97706)
                            : AppColors.primary;
                final icon = graduated
                    ? Icons.workspace_premium_rounded
                    : leftSchool
                        ? Icons.person_off_outlined
                        : repeated
                            ? Icons.replay_rounded
                            : Icons.arrow_upward_rounded;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w800, color: color),
                    ),
                    subtitle: Text(
                      graduated
                          ? '${p.fromSession} → ${p.toSession} · ${p.fromClass} → Graduated'
                          : leftSchool
                              ? '${p.fromSession} → ${p.toSession} · left after ${p.fromClass}'
                              : repeated
                                  ? '${p.fromSession} → ${p.toSession} · stayed in ${p.fromClass}'
                                  : '${p.fromSession} → ${p.toSession} · ${p.fromClass} → ${p.toClass}',
                    ),
                  ),
                );
              }),
            ],

            if (classHistory.length > 1) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Class history',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              ...classHistory.map(
                (h) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.class_outlined),
                    title: Text(h.className),
                    subtitle: Text(h.session),
                  ),
                ),
              ),
            ],

            buildTile(Icons.groups, "Parent / Guardian", student.parentName),

            buildTile(Icons.phone, "Phone", student.phone),

            buildTile(Icons.email, "Email", student.email),

            buildTile(Icons.home, "Address", student.address),

            buildTile(Icons.location_city, "State", student.state),

            buildTile(Icons.map, "Local Government", student.localGovernment),

            buildTile(Icons.flag, "Nationality", student.nationality),

            buildTile(Icons.mosque, "Religion", student.religion),

            buildTile(Icons.bloodtype, "Blood Group", student.bloodGroup),

            buildTile(Icons.science, "Genotype", student.genotype),

            buildTile(
              Icons.local_hospital,
              "Medical Condition",
              student.medicalCondition,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
