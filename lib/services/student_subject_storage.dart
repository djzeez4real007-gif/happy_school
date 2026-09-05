import '../database/fs.dart';
import '../models/student_subject.dart';

class StudentSubjectStorage {
  static const String boxName = 'student_subjects';

  static Future<void> assignSubject(StudentSubject subject) async {
    final a = subject.admissionNo.trim().toLowerCase();
    final c = subject.subjectCode.trim().toLowerCase();
    final se = subject.session.trim().toLowerCase();
    final t = subject.term.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final e = StudentSubject.fromMap(Map<String, dynamic>.from(r));
        if (e.admissionNo.trim().toLowerCase() == a &&
            e.subjectCode.trim().toLowerCase() == c &&
            e.session.trim().toLowerCase() == se &&
            e.term.trim().toLowerCase() == t) {
          final id = r['_docId']?.toString();
          if (id != null) {
            await Fs.set(boxName, id, subject.toMap());
            return;
          }
        }
      } catch (_) {}
    }
    await Fs.add(boxName, subject.toMap());
  }

  static Future<List<StudentSubject>> getSubjects(String admissionNo) async {
    final a = admissionNo.trim().toLowerCase();
    return (await getAllSubjects())
        .where((e) => e.admissionNo.trim().toLowerCase() == a)
        .toList();
  }

  static Future<List<StudentSubject>> getSubjectsForPeriod({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final a = admissionNo.trim().toLowerCase();
    final se = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    return (await getAllSubjects()).where((e) =>
        e.admissionNo.trim().toLowerCase() == a &&
        e.session.trim().toLowerCase() == se &&
        e.term.trim().toLowerCase() == t).toList();
  }

  static Future<List<StudentSubject>> getAllSubjects() async {
    final list = <StudentSubject>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(StudentSubject.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<List<StudentSubject>> getSubjectsByClass({
    required String className,
    required String session,
    required String term,
  }) async {
    final c = className.trim().toLowerCase();
    final se = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    return (await getAllSubjects()).where((e) =>
        e.className.trim().toLowerCase() == c &&
        e.session.trim().toLowerCase() == se &&
        e.term.trim().toLowerCase() == t).toList();
  }

  static Future<void> deleteSubjects(String admissionNo) async {
    final a = admissionNo.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final e = StudentSubject.fromMap(Map<String, dynamic>.from(r));
        if (e.admissionNo.trim().toLowerCase() == a) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        }
      } catch (_) {}
    }
  }

  static Future<void> deleteSubjectsForPeriod({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final a = admissionNo.trim().toLowerCase();
    final se = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final e = StudentSubject.fromMap(Map<String, dynamic>.from(r));
        if (e.admissionNo.trim().toLowerCase() == a &&
            e.session.trim().toLowerCase() == se &&
            e.term.trim().toLowerCase() == t) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        }
      } catch (_) {}
    }
  }

  static Future<void> deleteSubject({
    required String admissionNo,
    required String subjectCode,
    required String session,
    required String term,
  }) async {
    final a = admissionNo.trim().toLowerCase();
    final c = subjectCode.trim().toLowerCase();
    final se = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final e = StudentSubject.fromMap(Map<String, dynamic>.from(r));
        if (e.admissionNo.trim().toLowerCase() == a &&
            e.subjectCode.trim().toLowerCase() == c &&
            e.session.trim().toLowerCase() == se &&
            e.term.trim().toLowerCase() == t) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        }
      } catch (_) {}
    }
  }

  static Future<StudentSubject?> getSubject({
    required String admissionNo,
    required String subjectCode,
    required String session,
    required String term,
  }) async {
    final a = admissionNo.trim().toLowerCase();
    final c = subjectCode.trim().toLowerCase();
    final se = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    for (final e in await getAllSubjects()) {
      if (e.admissionNo.trim().toLowerCase() == a &&
          e.subjectCode.trim().toLowerCase() == c &&
          e.session.trim().toLowerCase() == se &&
          e.term.trim().toLowerCase() == t) {
        return e;
      }
    }
    return null;
  }

  static Future<int> getTotalAssignments() async => Fs.count(boxName);
}
