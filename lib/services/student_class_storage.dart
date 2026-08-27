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

  static Box<Map> _box() => Hive.box<Map>(boxName);

  static StudentClass _fromAny(dynamic raw) {
    if (raw is Map) {
      return StudentClass.fromMap(Map<String, dynamic>.from(raw));
    }
    return StudentClass(
      admissionNo: '',
      studentName: '',
      className: '',
      session: '',
    );
  }

  /// Assignment identity = admissionNo + session (term is legacy only).
  static Future<void> assignStudent(StudentClass item) async {
    final box = _box();
    final adm = item.admissionNo.trim().toLowerCase();
    final sess = item.session.trim().toLowerCase();

    for (int i = 0; i < box.length; i++) {
      final rawAt = box.getAt(i);
      if (rawAt == null) continue;
      final existing = _fromAny(rawAt);
      final sameStudent = existing.admissionNo.trim().toLowerCase() == adm;
      final sameSession = existing.session.trim().toLowerCase() == sess;
      if (sameStudent && sameSession) {
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
    final box = _box();
    final List<StudentClass> students = [];
    for (final raw in box.values) {
      try {
        final s = _fromAny(raw);
        if (s.admissionNo.trim().isNotEmpty) students.add(s);
      } catch (_) {}
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
    final box = _box();

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
    final box = _box();

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
    final box = _box();

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
    // Prefer exact admission + session (ignore term — session-based placement).
    final targetAdmission = admissionNo.trim().toLowerCase();
    final targetSession = session.trim().toLowerCase();
    StudentClass? sessionMatch;

    for (final student in await getStudents()) {
      final sameAdmission =
          student.admissionNo.trim().toLowerCase() == targetAdmission;
      final sameSession =
          student.session.trim().toLowerCase() == targetSession;
      if (!sameAdmission || !sameSession) continue;

      final sameTerm =
          student.term.trim().toLowerCase() == term.trim().toLowerCase();
      if (sameTerm) return student;
      sessionMatch ??= student;
    }
    return sessionMatch;
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
    final box = _box();

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
    final box = _box();

    await box.clear();
    await box.flush();
  }
}
