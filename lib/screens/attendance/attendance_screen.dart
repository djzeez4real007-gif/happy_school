// lib/screens/attendance/attendance_screen.dart

import 'package:flutter/material.dart';

import '../../core/utils/sessions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import 'package:intl/intl.dart';

import '../../models/attendance.dart';
import '../../models/school_class.dart';
import '../../models/student.dart';

import '../../services/audit_log_storage.dart';
import '../../services/attendance_storage.dart';
import '../../services/class_storage.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<SchoolClass> classes = [];
  List<Student> students = [];
  List<Student> filteredStudents = [];

  SchoolClass? selectedClass;

  String selectedSession = "2026/2027";
  String selectedTerm = "First Term";

  DateTime selectedDate = DateTime.now();

  // ============================================================
  // SESSIONS
  // ============================================================

  final List<String> sessions = Sessions.list();

  final List<String> terms = ["First Term", "Second Term", "Third Term"];

  // ============================================================
  // ATTENDANCE DATA
  // ============================================================

  final Map<String, String> attendanceStatus = {};

  final Map<String, TextEditingController> remarkControllers = {};

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController searchController = TextEditingController();

  // ============================================================
  // SELECTED STUDENTS FOR BULK ACTIONS
  // ============================================================

  final Set<String> selectedStudents = {};

  bool loading = false;

  String get dateText {
    return DateFormat("dd/MM/yyyy").format(selectedDate);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> loadClasses() async {
    final loadedClasses = await ClassStorage.getClasses();

    if (!mounted) return;

    setState(() {
      classes = loadedClasses;
    });
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

  Future<void> loadStudents() async {
    if (selectedClass == null) return;

    final allStudents = await StudentStorage.getStudents();
    final assignedData = await StudentClassStorage.getStudents();

    // Strict match: JSS1 A ≠ JSS1 B / JSS1 C
    String normClass(String v) =>
        v.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

    final selectedFull = selectedClass!.fullClassName.trim().toLowerCase();
    final selectedNorm = normClass(selectedClass!.fullClassName);

    final assignedToClass = assignedData.where((e) {
      if (e.session.trim() != selectedSession) return false;
      final aClass = e.className.trim().toLowerCase();
      final aNorm = normClass(e.className);
      return aClass == selectedFull || aNorm == selectedNorm;
    }).toList();

    final assignedAdmissionNos = assignedToClass.map((e) => e.admissionNo).toSet();

    final loadedStudents = allStudents.where((student) {
      return assignedAdmissionNos.contains(student.admissionNo);
    }).toList();

    final existing = await AttendanceStorage.getByClassAndDate(
      className: selectedClass!.fullClassName,
      date: dateText,
      session: selectedSession,
      term: selectedTerm,
    );

    final existingMap = <String, Attendance>{};

    for (final record in existing) {
      existingMap[record.admissionNo] = record;
    }

    attendanceStatus.clear();
    selectedStudents.clear();

    for (final student in loadedStudents) {
      final existingRecord = existingMap[student.admissionNo];

      attendanceStatus[student.admissionNo] =
          existingRecord?.status ?? "Present";

      remarkControllers.putIfAbsent(
        student.admissionNo,
        () => TextEditingController(text: existingRecord?.remark ?? ""),
      );

      if (existingRecord != null) {
        remarkControllers[student.admissionNo]!.text = existingRecord.remark;
      }
    }

    if (!mounted) return;

    setState(() {
      students = loadedStudents;
      filteredStudents = loadedStudents;
    });
  }

  // ============================================================
  // SEARCH STUDENTS
  // ============================================================

  void searchStudents(String value) {
    final keyword = value.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        filteredStudents = students;
        return;
      }

      filteredStudents = students.where((student) {
        return student.fullName.toLowerCase().contains(keyword) ||
            student.firstName.toLowerCase().contains(keyword) ||
            student.surname.toLowerCase().contains(keyword) ||
            student.admissionNo.toLowerCase().contains(keyword);
      }).toList();
    });
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    if (!mounted) return;

    setState(() {
      selectedDate = picked;
    });

    await loadStudents();
  }

  // ============================================================
  // SET STATUS FOR ONE STUDENT
  // ============================================================

  void setStudentStatus(Student student, String status) {
    setState(() {
      attendanceStatus[student.admissionNo] = status;
    });
  }

  // ============================================================
  // SELECT / UNSELECT ONE STUDENT
  // ============================================================

  void toggleStudentSelection(Student student) {
    setState(() {
      if (selectedStudents.contains(student.admissionNo)) {
        selectedStudents.remove(student.admissionNo);
      } else {
        selectedStudents.add(student.admissionNo);
      }
    });
  }

  // ============================================================
  // SELECT ALL VISIBLE STUDENTS
  // ============================================================

  void selectAllVisibleStudents() {
    setState(() {
      for (final student in filteredStudents) {
        selectedStudents.add(student.admissionNo);
      }
    });
  }

  // ============================================================
  // CLEAR SELECTION
  // ============================================================

  void clearSelection() {
    setState(() {
      selectedStudents.clear();
    });
  }

  // ============================================================
  // MARK ALL STUDENTS PRESENT
  // ============================================================

  void markAllPresent() {
    setState(() {
      for (final student in students) {
        attendanceStatus[student.admissionNo] = "Present";
      }

      selectedStudents.clear();
    });

    PremiumFeedback.success(context, title: "All marked Present", subtitle: "Attendance updated for visible students");
  }

  // ============================================================
  // BULK STATUS
  // ============================================================

  void bulkMarkStatus(String status) {
    if (selectedStudents.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ); PremiumFeedback.info(context, title: "Select students first");
      return;
    }

    setState(() {
      for (final admissionNo in selectedStudents) {
        attendanceStatus[admissionNo] = status;
      }

      selectedStudents.clear();
    });

    PremiumFeedback.success(context, title: "Attendance updated", subtitle: "Selected students marked $status");
  }

  // ============================================================
  // SAVE ATTENDANCE
  // ============================================================

  Future<void> saveAttendance() async {
    if (selectedClass == null || students.isEmpty) {
      return;
    }

    setState(() {
      loading = true;
    });

    final List<Attendance> records = [];

    for (final student in students) {
      final status = attendanceStatus[student.admissionNo] ?? "Present";

      final remark = remarkControllers[student.admissionNo]?.text.trim() ?? "";

      records.add(
        Attendance(
          id: "${student.admissionNo}_${dateText}_${selectedSession}_$selectedTerm",
          admissionNo: student.admissionNo,
          studentName: student.fullName,
          className: selectedClass!.fullClassName,
          session: selectedSession,
          term: selectedTerm,
          date: dateText,
          status: status,
          remark: remark,
        ),
      );
    }

    await AttendanceStorage.saveMany(records);
    await AuditLogStorage.log(
      action: 'attendance_saved',
      module: 'attendance',
      description: 'Saved attendance (${records.length} records)',
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Attendance saved successfully."),
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshAttendance() async {
    await loadClasses();
    await loadStudents();
  }

  // ============================================================
  // STATUS BUTTON
  // ============================================================

  Widget buildStatusButton({
    required Student student,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    final selected = attendanceStatus[student.admissionNo] == status;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton.icon(
          onPressed: () {
            setStudentStatus(student, status);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? color : null,
            foregroundColor: selected ? Colors.white : color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 6),
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(icon, size: 14),
          label: Text(status, style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget buildStudentCard(Student student) {
    final status = attendanceStatus[student.admissionNo] ?? "Present";

    final isSelected = selectedStudents.contains(student.admissionNo);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    toggleStudentSelection(student);
                  },
                ),

                CircleAvatar(
                  radius: 22,
                  child: Text(
                    student.firstName.isEmpty
                        ? "?"
                        : student.firstName[0].toUpperCase(),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        student.admissionNo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: status == "Present"
                        ? Colors.green.shade100
                        : status == "Absent"
                        ? Colors.red.shade100
                        : status == "Late"
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: status == "Present"
                          ? Colors.green.shade800
                          : status == "Absent"
                          ? Colors.red.shade800
                          : status == "Late"
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                buildStatusButton(
                  student: student,
                  status: "Present",
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                buildStatusButton(
                  student: student,
                  status: "Absent",
                  color: Colors.red,
                  icon: Icons.cancel,
                ),
                buildStatusButton(
                  student: student,
                  status: "Late",
                  color: Colors.orange,
                  icon: Icons.access_time,
                ),
                buildStatusButton(
                  student: student,
                  status: "Excused",
                  color: Colors.blue,
                  icon: Icons.info,
                ),
              ],
            ),

            const SizedBox(height: 10),

            TextField(
              controller: remarkControllers[student.admissionNo],
              decoration: const InputDecoration(
                labelText: "Remark",
                hintText: "Optional remark",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final presentCount = attendanceStatus.values
        .where((e) => e == "Present")
        .length;

    final absentCount = attendanceStatus.values
        .where((e) => e == "Absent")
        .length;

    final lateCount = attendanceStatus.values.where((e) => e == "Late").length;

    final excusedCount = attendanceStatus.values
        .where((e) => e == "Excused")
        .length;

    final allVisibleSelected =
        filteredStudents.isNotEmpty &&
        filteredStudents.every(
          (student) => selectedStudents.contains(student.admissionNo),
        );

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Attendance",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: students.isEmpty ? null : refreshAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: Column(
        children: [
          // ======================================================
          // FILTERS
          // ======================================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedSession,
                  decoration: const InputDecoration(
                    labelText: "Session",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: sessions.map((session) {
                    return DropdownMenuItem<String>(
                      value: session,
                      child: Text(session),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      selectedSession = value;
                    });
                    await loadStudents();
                  },
                ),

                const SizedBox(height: 12),

DropdownButtonFormField<String>(
                  value: selectedClass?.fullClassName,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Select Class",
                    prefixIcon: Icon(Icons.school_rounded, color: AppColors.primary),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  items: classes.map((schoolClass) {
                    return DropdownMenuItem<String>(
                      value: schoolClass.fullClassName,
                      child: Text(schoolClass.fullClassName),
                    );
                  }).toList(),
                  onTap: () {
                    loadClasses();
                  },
                  onChanged: (value) async {
                    setState(() {
                      if (value == null) {
                        selectedClass = null;
                      } else {
                        try {
                          selectedClass = classes.firstWhere(
                            (c) => c.fullClassName == value,
                          );
                        } catch (_) {
                          selectedClass = null;
                        }
                      }
                      students = [];
                      filteredStudents = [];
                      selectedStudents.clear();
                    });

                    await loadStudents();
                  },
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: selectedTerm,
                  decoration: const InputDecoration(
                    labelText: "Term",
                    border: OutlineInputBorder(),
                  ),
                  items: terms.map((term) {
                    return DropdownMenuItem<String>(
                      value: term,
                      child: Text(term),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      selectedTerm = value;
                    });
                    await loadStudents();
                  },
                ),

                const SizedBox(height: 12),

InkWell(
                  onTap: selectDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Attendance Date",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(dateText),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // SEARCH
          // ======================================================
          if (students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: searchStudents,
                decoration: InputDecoration(
                  hintText: "Search student name or admission number...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            searchStudents("");
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // ======================================================
          // ATTENDANCE SUMMARY
          // ======================================================
          if (students.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _summaryChip("Total", students.length, Colors.blue),
                  _summaryChip("Present", presentCount, Colors.green),
                  _summaryChip("Absent", absentCount, Colors.red),
                  _summaryChip("Late", lateCount, Colors.orange),
                  _summaryChip("Excused", excusedCount, Colors.indigo),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ======================================================
          // BULK CONTROLS
          // ======================================================
          if (students.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedStudents.isEmpty
                              ? "Bulk Attendance"
                              : "${selectedStudents.length} selected",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      TextButton.icon(
                        onPressed: allVisibleSelected
                            ? clearSelection
                            : selectAllVisibleStudents,
                        icon: Icon(
                          allVisibleSelected
                              ? Icons.deselect
                              : Icons.select_all,
                        ),
                        label: Text(
                          allVisibleSelected ? "Clear" : "Select All",
                        ),
                      ),

                      TextButton.icon(
                        onPressed: markAllPresent,
                        icon: const Icon(Icons.done_all, color: Colors.green),
                        label: const Text(
                          "All Present",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),

                  if (selectedStudents.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _bulkButton(
                            "Absent",
                            Colors.red,
                            Icons.cancel,
                            () => bulkMarkStatus("Absent"),
                          ),
                          _bulkButton(
                            "Late",
                            Colors.orange,
                            Icons.access_time,
                            () => bulkMarkStatus("Late"),
                          ),
                          _bulkButton(
                            "Excused",
                            Colors.blue,
                            Icons.info,
                            () => bulkMarkStatus("Excused"),
                          ),
                          _bulkButton(
                            "Present",
                            Colors.green,
                            Icons.check_circle,
                            () => bulkMarkStatus("Present"),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // ======================================================
          // STUDENT LIST
          // ======================================================
          Expanded(
            child: selectedClass == null
                ? const Center(
                    child: Text("Select a class to begin attendance."),
                  )
                : students.isEmpty
                ? const Center(child: Text("No students found."))
                : filteredStudents.isEmpty
                ? const Center(child: Text("No matching student found."))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      return buildStudentCard(filteredStudents[index]);
                    },
                  ),
          ),
        ],
      ),

      // ========================================================
      // SAVE
      // ========================================================
      bottomNavigationBar: students.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : saveAttendance,
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(loading ? "Saving..." : "SAVE ATTENDANCE"),
                  ),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // SUMMARY CHIP
  // ============================================================

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        "$label: $count",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // BULK BUTTON
  // ============================================================

  Widget _bulkButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();

    for (final controller in remarkControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
}