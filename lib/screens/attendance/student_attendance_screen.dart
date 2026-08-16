// lib/screens/attendance/student_attendance_screen.dart

import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../services/attendance_storage.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String admissionNo;
  final String studentName;

  const StudentAttendanceScreen({
    super.key,
    required this.admissionNo,
    required this.studentName,
  });

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<Attendance> records = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final loaded = await AttendanceStorage.getStudentAttendance(
      widget.admissionNo,
    );

    loaded.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;

    setState(() {
      records = loaded;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = records.length;

    final present = records.where((e) => e.status == "Present").length;

    final absent = records.where((e) => e.status == "Absent").length;

    final late = records.where((e) => e.status == "Late").length;

    final excused = records.where((e) => e.status == "Excused").length;

    final percentage = total == 0 ? 0.0 : (present / total) * 100;

    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            "Attendance Percentage",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${percentage.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _stat("Total", total, Colors.blue),
                              ),
                              Expanded(
                                child: _stat("Present", present, Colors.green),
                              ),
                              Expanded(
                                child: _stat("Absent", absent, Colors.red),
                              ),
                              Expanded(
                                child: _stat("Late", late, Colors.orange),
                              ),
                              Expanded(
                                child: _stat("Excused", excused, Colors.purple),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text("No attendance records found."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final item = records[index];

                            final color = item.status == "Present"
                                ? Colors.green
                                : item.status == "Absent"
                                ? Colors.red
                                : item.status == "Late"
                                ? Colors.orange
                                : Colors.blue;

                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  item.status == "Present"
                                      ? Icons.check_circle
                                      : item.status == "Absent"
                                      ? Icons.cancel
                                      : item.status == "Late"
                                      ? Icons.access_time
                                      : Icons.info,
                                  color: color,
                                ),
                                title: Text(
                                  item.date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${item.className} • ${item.session} • ${item.term}${item.remark.isEmpty ? "" : "\n${item.remark}"}",
                                ),
                                trailing: Text(
                                  item.status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  Widget _stat(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
