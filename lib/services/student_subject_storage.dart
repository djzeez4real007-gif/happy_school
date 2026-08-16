import 'package:hive_flutter/hive_flutter.dart';

import '../models/student_subject.dart';

class StudentSubjectStorage {
  static const String boxName = 'student_subjects';

  // ==========================================================
  // ASSIGN / UPDATE SUBJECT
  // ==========================================================
  //
  // A student's subject assignment is unique by:
  //
  // admissionNo + subjectCode + session + term
  //
  // This allows the same student to have different subjects
  // across different sessions/terms.
  //
  // ==========================================================

  static Future<void> assignSubject(StudentSubject subject) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = subject.admissionNo.trim().toLowerCase();

    final targetSubjectCode = subject.subjectCode.trim().toLowerCase();

    final targetSession = subject.session.trim().toLowerCase();

    final targetTerm = subject.term.trim().toLowerCase();

    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);

      if (raw == null) {
        continue;
      }

      final existing = StudentSubject.fromMap(Map<String, dynamic>.from(raw));

      final sameAdmission =
          existing.admissionNo.trim().toLowerCase() == targetAdmission;

      final sameSubject =
          existing.subjectCode.trim().toLowerCase() == targetSubjectCode;

      final sameSession =
          existing.session.trim().toLowerCase() == targetSession;

      final sameTerm = existing.term.trim().toLowerCase() == targetTerm;

      if (sameAdmission && sameSubject && sameSession && sameTerm) {
        await box.putAt(i, subject.toMap());
        await box.flush();
        return;
      }
    }

    await box.add(subject.toMap());
    await box.flush();
  }

  // ==========================================================
  // GET ALL SUBJECTS FOR ONE STUDENT
  // ==========================================================

  static Future<List<StudentSubject>> getSubjects(String admissionNo) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    return box.values
        .map((raw) => StudentSubject.fromMap(Map<String, dynamic>.from(raw)))
        .where(
          (subject) =>
              subject.admissionNo.trim().toLowerCase() == targetAdmission,
        )
        .toList();
  }

  // ==========================================================
  // GET STUDENT SUBJECTS FOR SESSION + TERM
  // ==========================================================

  static Future<List<StudentSubject>> getSubjectsForPeriod({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    final targetSession = session.trim().toLowerCase();

    final targetTerm = term.trim().toLowerCase();

    return box.values
        .map((raw) => StudentSubject.fromMap(Map<String, dynamic>.from(raw)))
        .where((subject) {
          final sameAdmission =
              subject.admissionNo.trim().toLowerCase() == targetAdmission;

          final sameSession =
              subject.session.trim().toLowerCase() == targetSession;

          final sameTerm = subject.term.trim().toLowerCase() == targetTerm;

          return sameAdmission && sameSession && sameTerm;
        })
        .toList();
  }

  // ==========================================================
  // GET ALL SUBJECT ASSIGNMENTS
  // ==========================================================

  static Future<List<StudentSubject>> getAllSubjects() async {
    final box = Hive.box<Map>(boxName);

    return box.values
        .map((raw) => StudentSubject.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  // ==========================================================
  // GET SUBJECTS BY CLASS + SESSION + TERM
  // ==========================================================

  static Future<List<StudentSubject>> getSubjectsByClass({
    required String className,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final targetClass = className.trim().toLowerCase();

    final targetSession = session.trim().toLowerCase();

    final targetTerm = term.trim().toLowerCase();

    return box.values
        .map((raw) => StudentSubject.fromMap(Map<String, dynamic>.from(raw)))
        .where((subject) {
          final sameClass =
              subject.className.trim().toLowerCase() == targetClass;

          final sameSession =
              subject.session.trim().toLowerCase() == targetSession;

          final sameTerm = subject.term.trim().toLowerCase() == targetTerm;

          return sameClass && sameSession && sameTerm;
        })
        .toList();
  }

  // ==========================================================
  // DELETE ALL SUBJECTS FOR ONE STUDENT
  // ==========================================================
  //
  // Used when changing a student's class or promoting them.
  //
  // ==========================================================

  static Future<void> deleteSubjects(String admissionNo) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    for (int i = box.length - 1; i >= 0; i--) {
      final raw = box.getAt(i);

      if (raw == null) {
        continue;
      }

      final subject = StudentSubject.fromMap(Map<String, dynamic>.from(raw));

      if (subject.admissionNo.trim().toLowerCase() == targetAdmission) {
        await box.deleteAt(i);
      }
    }

    await box.flush();
  }

  // ==========================================================
  // DELETE SUBJECTS FOR ONE STUDENT + SESSION + TERM
  // ==========================================================

  static Future<void> deleteSubjectsForPeriod({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    final targetSession = session.trim().toLowerCase();

    final targetTerm = term.trim().toLowerCase();

    for (int i = box.length - 1; i >= 0; i--) {
      final raw = box.getAt(i);

      if (raw == null) {
        continue;
      }

      final subject = StudentSubject.fromMap(Map<String, dynamic>.from(raw));

      final sameAdmission =
          subject.admissionNo.trim().toLowerCase() == targetAdmission;

      final sameSession = subject.session.trim().toLowerCase() == targetSession;

      final sameTerm = subject.term.trim().toLowerCase() == targetTerm;

      if (sameAdmission && sameSession && sameTerm) {
        await box.deleteAt(i);
      }
    }

    await box.flush();
  }

  // ==========================================================
  // DELETE ONE SUBJECT ASSIGNMENT
  // ==========================================================

  static Future<void> deleteSubject({
    required String admissionNo,
    required String subjectCode,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    final targetSubjectCode = subjectCode.trim().toLowerCase();

    final targetSession = session.trim().toLowerCase();

    final targetTerm = term.trim().toLowerCase();

    for (int i = box.length - 1; i >= 0; i--) {
      final raw = box.getAt(i);

      if (raw == null) {
        continue;
      }

      final subject = StudentSubject.fromMap(Map<String, dynamic>.from(raw));

      final sameAdmission =
          subject.admissionNo.trim().toLowerCase() == targetAdmission;

      final sameSubject =
          subject.subjectCode.trim().toLowerCase() == targetSubjectCode;

      final sameSession = subject.session.trim().toLowerCase() == targetSession;

      final sameTerm = subject.term.trim().toLowerCase() == targetTerm;

      if (sameAdmission && sameSubject && sameSession && sameTerm) {
        await box.deleteAt(i);
        await box.flush();
        return;
      }
    }
  }

  // ==========================================================
  // GET ONE SUBJECT ASSIGNMENT
  // ==========================================================

  static Future<StudentSubject?> getSubject({
    required String admissionNo,
    required String subjectCode,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final targetAdmission = admissionNo.trim().toLowerCase();

    final targetSubjectCode = subjectCode.trim().toLowerCase();

    final targetSession = session.trim().toLowerCase();

    final targetTerm = term.trim().toLowerCase();

    for (final raw in box.values) {
      final subject = StudentSubject.fromMap(Map<String, dynamic>.from(raw));

      final sameAdmission =
          subject.admissionNo.trim().toLowerCase() == targetAdmission;

      final sameSubject =
          subject.subjectCode.trim().toLowerCase() == targetSubjectCode;

      final sameSession = subject.session.trim().toLowerCase() == targetSession;

      final sameTerm = subject.term.trim().toLowerCase() == targetTerm;

      if (sameAdmission && sameSubject && sameSession && sameTerm) {
        return subject;
      }
    }

    return null;
  }

  // ==========================================================
  // TOTAL SUBJECT ASSIGNMENTS
  // ==========================================================

  static Future<int> getTotalAssignments() async {
    final box = Hive.box<Map>(boxName);

    return box.length;
  }
}
