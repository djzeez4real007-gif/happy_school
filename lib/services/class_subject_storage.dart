import '../database/fs.dart';
import '../models/class_subject.dart';

class ClassSubjectStorage {
  static const String boxName = 'class_subjects';

  static String _norm(String s) => s.trim().toLowerCase();

  static Future<void> assignSubject(ClassSubject item) async {
    final rows = await Fs.getAll(boxName);
    for (final r in rows) {
      try {
        final e = ClassSubject.fromMap(Map<String, dynamic>.from(r));
        if (_norm(e.className) == _norm(item.className) &&
            _norm(e.subjectCode) == _norm(item.subjectCode)) {
          final id = r['_docId']?.toString();
          if (id != null) {
            await Fs.set(boxName, id, item.toMap());
            return;
          }
        }
      } catch (_) {}
    }
    await Fs.add(boxName, item.toMap());
  }

  static Future<List<ClassSubject>> getAssignments() async {
    final list = <ClassSubject>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(ClassSubject.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<List<ClassSubject>> getClassSubjects(String className) async {
    final c = _norm(className);
    return (await getAssignments())
        .where((e) => _norm(e.className) == c)
        .toList();
  }

  static Future<ClassSubject?> getAssignment({
    required String className,
    required String subjectCode,
  }) async {
    final c = _norm(className);
    final s = _norm(subjectCode);
    for (final e in await getAssignments()) {
      if (_norm(e.className) == c && _norm(e.subjectCode) == s) return e;
    }
    return null;
  }

  static Future<void> deleteAssignment(int index) async =>
      Fs.deleteAt(boxName, index);

  static Future<void> removeSubjectFromClass({
    required String className,
    required String subjectCode,
  }) async {
    final c = _norm(className);
    final s = _norm(subjectCode);
    for (final r in await Fs.getAll(boxName)) {
      try {
        final e = ClassSubject.fromMap(Map<String, dynamic>.from(r));
        if (_norm(e.className) == c && _norm(e.subjectCode) == s) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        }
      } catch (_) {}
    }
  }

  static Future<void> deleteClassSubjects(String className) async {
    final c = _norm(className);
    for (final r in await Fs.getAll(boxName)) {
      try {
        final e = ClassSubject.fromMap(Map<String, dynamic>.from(r));
        if (_norm(e.className) == c) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        }
      } catch (_) {}
    }
  }
}
