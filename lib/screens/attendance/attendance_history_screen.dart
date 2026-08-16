// lib/screens/attendance/attendance_history_screen.dart

import 'package:flutter/material.dart';

import '../../models/attendance.dart';
import '../../services/attendance_storage.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<Attendance> records = [];

  bool loading = true;

  String filter = "All";

  final List<String> filters = ["All", "Present", "Absent", "Late", "Excused"];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final loaded = await AttendanceStorage.getAttendance();

    loaded.sort((a, b) {
      return b.date.compareTo(a.date);
    });

    if (!mounted) return;

    setState(() {
      records = loaded;
      loading = false;
    });
  }

  List<Attendance> get filteredRecords {
    if (filter == "All") {
      return records;
    }

    return records.where((item) => item.status == filter).toList();
  }

  Widget summaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 5),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteRecord(Attendance attendance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Attendance"),
          content: Text(
            "Delete attendance for ${attendance.studentName} on ${attendance.date}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await AttendanceStorage.deleteAttendance(attendance.id);

    await loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredRecords;

    final present = records.where((e) => e.status == "Present").length;

    final absent = records.where((e) => e.status == "Absent").length;

    final late = records.where((e) => e.status == "Late").length;

    final excused = records.where((e) => e.status == "Excused").length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        actions: [
          IconButton(onPressed: loadRecords, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      summaryCard(
                        "Present",
                        present,
                        Colors.green,
                        Icons.check_circle,
                      ),
                      summaryCard("Absent", absent, Colors.red, Icons.cancel),
                      summaryCard(
                        "Late",
                        late,
                        Colors.orange,
                        Icons.access_time,
                      ),
                      summaryCard("Excused", excused, Colors.blue, Icons.info),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: filter,
                    decoration: const InputDecoration(
                      labelText: "Filter Attendance",
                      border: OutlineInputBorder(),
                    ),
                    items: filters.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        filter = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text("No attendance records found."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];

                            final Color statusColor = item.status == "Present"
                                ? Colors.green
                                : item.status == "Absent"
                                ? Colors.red
                                : item.status == "Late"
                                ? Colors.orange
                                : Colors.blue;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    item.status == "Present"
                                        ? Icons.check
                                        : item.status == "Absent"
                                        ? Icons.close
                                        : item.status == "Late"
                                        ? Icons.access_time
                                        : Icons.info,
                                    color: statusColor,
                                  ),
                                ),
                                title: Text(
                                  item.studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${item.className}\n${item.date} • ${item.session} • ${item.term}",
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => deleteRecord(item),
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
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
