import '../database/fs.dart';
import '../models/subject.dart';

class SubjectStorage {
  static const String boxName = 'subjects';

  static Future<void> addSubject(Subject subject) async {
    final code = subject.subjectCode.trim().toLowerCase();
    final cls = subject.studentClass.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final s = Subject.fromMap(Map<String, dynamic>.from(r));
        if (s.subjectCode.trim().toLowerCase() == code &&
            s.studentClass.trim().toLowerCase() == cls) {
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

  static Future<List<Subject>> getSubjects() async {
    final list = <Subject>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(Subject.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> removeDuplicateSubjects() async {
    final seen = <String>{};
    for (final r in await Fs.getAll(boxName)) {
      try {
        final s = Subject.fromMap(Map<String, dynamic>.from(r));
        final key =
            '${s.subjectCode.trim().toLowerCase()}|${s.studentClass.trim().toLowerCase()}';
        if (key == '|' || seen.contains(key)) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        } else {
          seen.add(key);
        }
      } catch (_) {}
    }
  }

  static Future<int> getTotalSubjects() async => Fs.count(boxName);

  static Future<List<Subject>> getSubjectsByClass(String className) async {
    final c = className.trim().toLowerCase();
    return (await getSubjects())
        .where((s) =>
            s.studentClass.trim().isEmpty ||
            s.studentClass.trim().toLowerCase() == c)
        .toList();
  }

  static Future<Subject?> getSubject(String code, {String className = ''}) async {
    final c = code.trim().toLowerCase();
    final cls = className.trim().toLowerCase();
    for (final s in await getSubjects()) {
      if (s.subjectCode.trim().toLowerCase() != c) continue;
      if (cls.isNotEmpty &&
          s.studentClass.trim().isNotEmpty &&
          s.studentClass.trim().toLowerCase() != cls) {
        continue;
      }
      return s;
    }
    return null;
  }

  static Future<void> deleteSubjectByCode(String subjectCode) async {
    final code = subjectCode.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final s = Subject.fromMap(Map<String, dynamic>.from(r));
        if (s.subjectCode.trim().toLowerCase() == code) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
        }
      } catch (_) {}
    }
  }

  static Future<void> updateSubjectByCode(String oldCode, Subject subject) async {
    final code = oldCode.trim().toLowerCase();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final s = Subject.fromMap(Map<String, dynamic>.from(r));
        if (s.subjectCode.trim().toLowerCase() == code) {
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

  static Future<void> deleteSubject(int index) async =>
      Fs.deleteAt(boxName, index);

  static Future<void> updateSubject(int index, Subject subject) async =>
      Fs.putAt(boxName, index, subject.toMap());

  static Future<void> seedDefaultSubjects() async {
    final existing = await getSubjects();
    if (existing.isNotEmpty) {
      await removeDuplicateSubjects();
    }
  }
}
