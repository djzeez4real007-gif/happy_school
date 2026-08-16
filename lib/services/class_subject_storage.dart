import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_subject.dart';

class ClassSubjectStorage {
  static const String boxName = "class_subjects";

  static Future<void> assignSubject(ClassSubject item) async {
    final box = Hive.box<Map>(boxName);

    for (int i = 0; i < box.length; i++) {
      final existing = ClassSubject.fromMap(
        Map<String, dynamic>.from(box.getAt(i)!),
      );

      if (existing.className == item.className &&
          existing.subjectCode == item.subjectCode) {
        await box.putAt(i, item.toMap());
        return;
      }
    }

    await box.add(item.toMap());
  }

  static Future<List<ClassSubject>> getAssignments() async {
    final box = Hive.box<Map>(boxName);

    return box.values
        .map((e) => ClassSubject.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<ClassSubject>> getClassSubjects(String className) async {
    final assignments = await getAssignments();
    return assignments.where((e) => e.className == className).toList();
  }

  static Future<ClassSubject?> getAssignment({
    required String className,
    required String subjectCode,
  }) async {
    final box = Hive.box<Map>(boxName);

    for (final item in box.values) {
      final assignment = ClassSubject.fromMap(Map<String, dynamic>.from(item));

      if (assignment.className == className &&
          assignment.subjectCode == subjectCode) {
        return assignment;
      }
    }

    return null;
  }

  static Future<void> deleteAssignment(int index) async {
    final box = Hive.box<Map>(boxName);
    await box.deleteAt(index);
  }

  static Future<void> removeSubjectFromClass({
    required String className,
    required String subjectCode,
  }) async {
    final box = Hive.box<Map>(boxName);

    for (int i = box.length - 1; i >= 0; i--) {
      final item = ClassSubject.fromMap(
        Map<String, dynamic>.from(box.getAt(i)!),
      );

      if (item.className == className && item.subjectCode == subjectCode) {
        await box.deleteAt(i);
      }
    }
  }

  static Future<void> deleteClassSubjects(String className) async {
    final box = Hive.box<Map>(boxName);

    for (int i = box.length - 1; i >= 0; i--) {
      final item = ClassSubject.fromMap(
        Map<String, dynamic>.from(box.getAt(i)!),
      );

      if (item.className == className) {
        await box.deleteAt(i);
      }
    }
  }
}
