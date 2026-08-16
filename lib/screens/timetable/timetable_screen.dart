import 'package:flutter/material.dart';
import '../../services/audit_log_storage.dart';
import '../../core/theme/app_colors.dart';

import '../../models/timetable.dart';
import '../../services/timetable_storage.dart';

import 'timetable_form_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Timetable> timetables = [];

  bool loading = true;

  String selectedDay = "All Days";

  final List<String> days = [
    "All Days",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    setState(() {
      loading = true;
    });

    final data = await TimetableStorage.getTimetables();

    if (!mounted) return;

    setState(() {
      timetables = data;
      loading = false;
    });
  }

  List<Timetable> get filteredTimetables {
    if (selectedDay == "All Days") {
      return timetables;
    }

    return timetables.where((entry) => entry.day == selectedDay).toList();
  }

  Future<void> addTimetable() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimetableFormScreen()),
    );

    if (!mounted) return;

    await loadTimetable();
  }

  Future<void> editTimetable(Timetable timetable, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimetableFormScreen(timetable: timetable, index: index),
      ),
    );

    if (!mounted) return;

    await loadTimetable();
  }

  Future<void> deleteTimetable(Timetable timetable, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Timetable"),
          content: Text(
            "Delete ${timetable.subject} from "
            "${timetable.day} at ${timetable.period}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      await TimetableStorage.deleteTimetable(index);
      await AuditLogStorage.log(
        action: 'timetable_deleted',
        module: 'timetable',
        description: 'Timetable entry deleted',
      );

      if (!mounted) return;

      await loadTimetable();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Timetable entry deleted successfully."),
        ),
      );
    }
  }

  Color getDayColor(String day) {
    switch (day) {
      case "Monday":
        return Colors.blue;

      case "Tuesday":
        return Colors.green;

      case "Wednesday":
        return Colors.orange;

      case "Thursday":
        return Colors.purple;

      case "Friday":
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }

  Widget buildTimetableCard(Timetable timetable, int originalIndex) {
    final dayColor = getDayColor(timetable.day);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: dayColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timetable.day,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    timetable.period,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == "edit") {
                      await editTimetable(timetable, originalIndex);
                    }

                    if (value == "delete") {
                      await deleteTimetable(timetable, originalIndex);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 22),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Subject",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timetable.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.school, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timetable.className,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timetable.teacher,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.meeting_room,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timetable.room.isEmpty ? "No room" : timetable.room,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 20,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(timetable.term)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              timetable.session,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredTimetables;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: const Text(
          "Timetable",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: loadTimetable,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTimetable,
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            color: const Color(0xFF1D4ED8),
            child: DropdownButtonFormField<String>(
              initialValue: selectedDay,
              
              decoration: InputDecoration(
                labelText: "Filter by Day",
                labelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
                filled: true,
                
                prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1D4ED8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: days.map((day) {
                return DropdownMenuItem<String>(value: day, child: Text(day));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedDay = value;
                });
              },
            ),
          ),

          if (!loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "${filtered.length} timetable "
                    "${filtered.length == 1 ? 'entry' : 'entries'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 70,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "No timetable entries yet.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedDay == "All Days"
                                ? "Tap Add to create your first timetable entry."
                                : "No timetable entries for $selectedDay.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadTimetable,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final timetable = filtered[index];

                        final originalIndex = timetables.indexOf(timetable);

                        return buildTimetableCard(timetable, originalIndex);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}