import 'package:hive_flutter/hive_flutter.dart';

import '../models/student_class.dart';

class StudentClassStorage {
  static const String boxName = 'student_classes';

  // ==========================================================
  // ASSIGN / UPDATE STUDENT CLASS
  // ==========================================================
  //
  // A student's class assignment is identified by:
  //
  // admissionNo + session + term
  //
  // This allows the same student to have:
  //
  // 2025/2026 + Third Term  -> JSS 1
  // 2026/2027 + First Term  -> JSS 2
  //
  // Old assignments are NOT deleted when a student is promoted.
  //
  // ==========================================================

  static Future<void> assignStudent(StudentClass item) async {
    final box = Hive.box<Map>(boxName);

    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw == null) continue;

      final existing = StudentClass.fromMap(Map<String, dynamic>.from(raw));

      final sameStudent =
          existing.admissionNo.trim().toLowerCase() ==
          item.admissionNo.trim().toLowerCase();

      final sameSession =
          existing.session.trim().toLowerCase() ==
          item.session.trim().toLowerCase();

      final sameTerm =
          existing.term.trim().toLowerCase() == item.term.trim().toLowerCase();

      if (sameStudent && sameSession && sameTerm) {
        await box.putAt(i, item.toMap());
        await box.flush();
        return;
      }
    }

    await box.add(item.toMap());
    await box.flush();
  }

  // ==========================================================
  // GET ALL ASSIGNED STUDENTS
  // ==========================================================

  static Future<List<StudentClass>> getStudents() async {
    final box = Hive.box<Map>(boxName);

    final List<StudentClass> students = [];

    for (final raw in box.values) {
      students.add(StudentClass.fromMap(Map<String, dynamic>.from(raw)));
    }

    return students;
  }

  // ==========================================================
  // GET STUDENTS BY SESSION + TERM
  // ==========================================================

  static Future<List<StudentClass>> getStudentsBySessionTerm({
    required String session,
    required String term,
  }) async {
    final students = await getStudents();

    final targetSession = session.trim().toLowerCase();
    final targetTerm = term.trim().toLowerCase();

    return students.where((student) {
      return student.session.trim().toLowerCase() == targetSession &&
          student.term.trim().toLowerCase() == targetTerm;
    }).toList();
  }

  // ==========================================================
  // GET STUDENTS BY CLASS + SESSION + TERM
  // ==========================================================

  static Future<List<StudentClass>> getStudentsByClass({
    required String className,
    required String session,
    required String term,
  }) async {
    final students = await getStudents();

    final targetClass = className.trim().toLowerCase();
    final targetSession = session.trim().toLowerCase();

    // Class assignment is session-based — term is ignored
    return students.where((student) {
      final studentClass = student.className.trim().toLowerCase();
      final studentSession = student.session.trim().toLowerCase();

      return studentClass == targetClass &&
          studentSession == targetSession;
    }).toList();
  }

  // ==========================================================
  // UPDATE STUDENT CLASS
  // ==========================================================

  static Future<void> updateStudent(int index, StudentClass item) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    // Prevent duplicate admissionNo + session + term.
    for (int i = 0; i < box.length; i++) {
      if (i == index) {
        continue;
      }

      final raw = box.getAt(i);

      if (raw == null) continue;
      
      final existing = StudentClass.fromMap(Map<String, dynamic>.from(raw));

      final sameStudent =
          existing.admissionNo.trim().toLowerCase() ==
          item.admissionNo.trim().toLowerCase();

      final sameSession =
          existing.session.trim().toLowerCase() ==
          item.session.trim().toLowerCase();

      final sameTerm =
          existing.term.trim().toLowerCase() == item.term.trim().toLowerCase();

      if (sameStudent && sameSession && sameTerm) {
        return;
      }
    }

    await box.putAt(index, item.toMap());
    await box.flush();
  }

  // ==========================================================
  // DELETE STUDENT CLASS
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
  // GET ONE STUDENT CLASS
  // ==========================================================
  //
  // Returns the first assignment belonging to the admission
  // number.
  //
  // For a specific session/term, use getStudentForPeriod().
  //
  // ==========================================================

  static Future<StudentClass?> getStudent(String admissionNo) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    for (final raw in box.values) {
      final student = StudentClass.fromMap(Map<String, dynamic>.from(raw));

      if (student.admissionNo.trim().toLowerCase() == targetAdmission) {
        return student;
      }
    }

    return null;
  }

  // ==========================================================
  // GET ONE STUDENT CLASS FOR SESSION + TERM
  // ==========================================================

  static Future<StudentClass?> getStudentForPeriod({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();
    final targetSession = session.trim().toLowerCase();
    final targetTerm = term.trim().toLowerCase();

    for (final raw in box.values) {
      final student = StudentClass.fromMap(Map<String, dynamic>.from(raw));

      final sameAdmission =
          student.admissionNo.trim().toLowerCase() == targetAdmission;

      final sameSession = student.session.trim().toLowerCase() == targetSession;

      final sameTerm = student.term.trim().toLowerCase() == targetTerm;

      if (sameAdmission && sameSession && sameTerm) {
        return student;
      }
    }

    return null;
  }

  // ==========================================================
  // GET ALL ASSIGNMENTS FOR ONE STUDENT
  // ==========================================================
  //
  // Useful for promotion/history.
  //
  // Example:
  //
  // 2025/2026 -> JSS 1
  // 2026/2027 -> JSS 2
  // 2027/2028 -> JSS 3
  //
  // ==========================================================

  static Future<List<StudentClass>> getStudentHistory(
    String admissionNo,
  ) async {
    final students = await getStudents();

    final targetAdmission = admissionNo.trim().toLowerCase();

    return students.where((student) {
      return student.admissionNo.trim().toLowerCase() == targetAdmission;
    }).toList();
  }

  // ==========================================================
  // GET STUDENTS BY SESSION
  // ==========================================================

  static Future<List<StudentClass>> getStudentsBySession(String session) async {
    final students = await getStudents();

    final targetSession = session.trim().toLowerCase();

    return students.where((student) {
      return student.session.trim().toLowerCase() == targetSession;
    }).toList();
  }

  // ==========================================================
  // GET STUDENTS BY CLASS + SESSION
  // ==========================================================
  //
  // This is particularly useful for promotion.
  //
  // Example:
  //
  // JSS 1 A + 2025/2026
  //
  // ==========================================================

  static Future<List<StudentClass>> getStudentsByClassAndSession({
    required String className,
    required String session,
  }) async {
    final students = await getStudents();

    final targetClass = className.trim().toLowerCase();
    final targetSession = session.trim().toLowerCase();

    return students.where((student) {
      return student.className.trim().toLowerCase() == targetClass &&
          student.session.trim().toLowerCase() == targetSession;
    }).toList();
  }

  // ==========================================================
  // CHECK WHETHER STUDENT HAS ASSIGNMENT
  // ==========================================================

  static Future<bool> hasAssignment({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final student = await getStudentForPeriod(
      admissionNo: admissionNo,
      session: session,
      term: term,
    );

    return student != null;
  }

  // ==========================================================
  // TOTAL ASSIGNED STUDENTS
  // ==========================================================

  static Future<int> getTotalAssignedStudents() async {
    final box = Hive.box<Map>(boxName);

    return box.length;
  }

  // ==========================================================
  // CLEAR ALL ASSIGNMENTS
  // ==========================================================
  //
  // Use carefully. This removes ALL class assignments.
  //
  // ==========================================================

  static Future<void> clearAllAssignments() async {
    final box = Hive.box<Map>(boxName);

    await box.clear();
    await box.flush();
  }
}
