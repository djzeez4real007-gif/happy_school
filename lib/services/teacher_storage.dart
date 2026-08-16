import 'package:hive_flutter/hive_flutter.dart';
import '../models/teacher.dart';

class TeacherStorage {
  static const String boxName = "teachers";

  static Future<void> addTeacher(Teacher teacher) async {
    final box = Hive.box<Map>(boxName);

    for (int i = 0; i < box.length; i++) {
      final item = Teacher.fromMap(Map<String, dynamic>.from(box.getAt(i)!));

      if (item.staffId == teacher.staffId) {
        await box.putAt(i, teacher.toMap());
        await box.flush();
        return;
      }
    }

    await box.add(teacher.toMap());
    await box.flush();
  }

  static Future<List<Teacher>> getTeachers() async {
    final box = Hive.box<Map>(boxName);

    return box.values
        .map((e) => Teacher.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Teacher?> getTeacher(String staffId) async {
    final box = Hive.box<Map>(boxName);

    for (final item in box.values) {
      final teacher = Teacher.fromMap(Map<String, dynamic>.from(item));

      if (teacher.staffId == staffId) {
        return teacher;
      }
    }

    return null;
  }

  static Future<void> deleteTeacher(int index) async {
    final box = Hive.box<Map>(boxName);

    await box.deleteAt(index);
    await box.flush();
  }

  static Future<void> updateTeacher(int index, Teacher teacher) async {
    final box = Hive.box<Map>(boxName);

    await box.putAt(index, teacher.toMap());
    await box.flush();
  }
}
