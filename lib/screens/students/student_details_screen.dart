import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';
import 'student_registration_screen.dart';
import '../../services/id_card_pdf_service.dart';
import '../../services/id_card_pdf_service.dart';

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

    if (!mounted) return;

    setState(() {
      studentClass = result;
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
            onPressed: () async {
              await IdCardPdfService.generateStudentIdCard(
                student: widget.student,
                studentClass: studentClass,
                session: studentClass?.session.isNotEmpty == true
                    ? studentClass!.session
                    : '2026/2027',
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

            // Term removed — class assignment is session-based only.

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
