import 'package:hive_flutter/hive_flutter.dart';

import '../models/student.dart';

class StudentStorage {
  static const String boxName = 'students';

  // ==========================================================
  // ADD STUDENT
  // ==========================================================

  static Future<void> addStudent(Student student) async {
    final box = Hive.box<Map>(boxName);

    await box.add(student.toMap());
    await box.flush();
  }

  // ==========================================================
  // GET ALL STUDENTS
  // ==========================================================

  static Future<List<Student>> getStudents() async {
    final box = Hive.box<Map>(boxName);
    final list = <Student>[];
    for (final e in box.values) {
      try {
        list.add(Student.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  // ==========================================================
  // DELETE STUDENT
  // ==========================================================

  static Future<void> deleteStudent(int index) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    await box.deleteAt(index);
    await box.flush();
  }

  // ==========================================================
  // UPDATE STUDENT
  // ==========================================================

  static Future<void> updateStudent(int index, Student student) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    await box.putAt(index, student.toMap());
    await box.flush();
  }
}
