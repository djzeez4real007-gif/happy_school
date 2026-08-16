import 'package:flutter/material.dart';

import '../../models/school_class.dart';

import '../../services/class_storage.dart';
import '../../services/class_subject_storage.dart';

import 'class_subject_assignment_screen.dart';

class ClassSubjectDashboardScreen extends StatefulWidget {
  const ClassSubjectDashboardScreen({super.key});

  @override
  State<ClassSubjectDashboardScreen> createState() =>
      _ClassSubjectDashboardScreenState();
}

class _ClassSubjectDashboardScreenState
    extends State<ClassSubjectDashboardScreen> {
  List<SchoolClass> classes = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    classes = await ClassStorage.getClasses();
    setState(() {});
  }

  Future<List<String>> getSubjects(String className) async {
    final subjects = await ClassSubjectStorage.getClassSubjects(className);

    return subjects.map((e) => e.subjectName).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subject Assignment")),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Assign"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ClassSubjectAssignmentScreen(),
            ),
          );

          loadClasses();
        },
      ),

      body: ListView.builder(
        itemCount: classes.length,

        itemBuilder: (_, index) {
          final schoolClass = classes[index];

          return FutureBuilder<List<String>>(
            future: getSubjects(schoolClass.fullClassName),

            builder: (_, snapshot) {
              final subjectNames = snapshot.data ?? [];

              final count = subjectNames.length;

              Color color = Colors.red;
              String status = "Not Assigned";

              if (count > 0) {
                color = Colors.orange;
                status = "Incomplete";
              }

              if (count >= 10) {
                color = Colors.green;
                status = "Complete";
              }

              return Card(
                margin: const EdgeInsets.all(10),

                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(Icons.class_, color: color),
                  ),

                  title: Text(
                    schoolClass.fullClassName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text("Teacher: ${schoolClass.classTeacher}"),

                      Text(
                        "Subjects Assigned: $count",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 6),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: subjectNames.map((subject) {
                          return Chip(
                            label: Text(subject),
                            backgroundColor: Colors.blue.shade50,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 5),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.edit),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
