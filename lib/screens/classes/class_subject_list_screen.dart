import 'package:flutter/material.dart';

import '../../models/class_subject.dart';
import '../../services/class_subject_storage.dart';
import 'class_subject_assignment_screen.dart';

class ClassSubjectListScreen extends StatefulWidget {
  const ClassSubjectListScreen({super.key});

  @override
  State<ClassSubjectListScreen> createState() => _ClassSubjectListScreenState();
}

class _ClassSubjectListScreenState extends State<ClassSubjectListScreen> {
  List<ClassSubject> assignments = [];

  @override
  void initState() {
    super.initState();
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    assignments = await ClassSubjectStorage.getAssignments();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Subjects"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClassSubjectAssignmentScreen(),
                ),
              );

              loadAssignments();
            },
          ),
        ],
      ),

      body: assignments.isEmpty
          ? const Center(child: Text("No Assigned Subjects"))
          : ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final item = assignments[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  child: ListTile(
                    leading: const Icon(Icons.menu_book),

                    title: Text(item.subjectName),

                    subtitle: Text("${item.className} • ${item.subjectCode}"),

                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await ClassSubjectStorage.deleteAssignment(index);

                        loadAssignments();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
