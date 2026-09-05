import '../database/fs.dart';
import '../models/teacher_subject.dart';

class TeacherSubjectStorage {
  static const String boxName = 'teacher_subjects';

  static Future<List<TeacherSubject>> getAll() async {
    final list = <TeacherSubject>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(TeacherSubject.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<List<TeacherSubject>> forTeacher(String teacherId) async {
    final id = teacherId.trim().toLowerCase();
    final seen = <String>{};
    final out = <TeacherSubject>[];
    for (final t in await getAll()) {
      if (t.teacherId.trim().toLowerCase() != id) continue;
      final code = t.subjectCode.trim().toLowerCase();
      if (code.isEmpty || seen.contains(code)) continue;
      seen.add(code);
      out.add(t);
    }
    return out;
  }

  static Future<void> setForTeacher(
    String teacherId,
    List<TeacherSubject> subjects,
  ) async {
    final id = teacherId.trim();
    for (final r in await Fs.getAll(boxName)) {
      try {
        final t = TeacherSubject.fromMap(Map<String, dynamic>.from(r));
        if (t.teacherId.trim().toLowerCase() == id.toLowerCase()) {
          final docId = r['_docId']?.toString();
          if (docId != null) await Fs.delete(boxName, docId);
        }
      } catch (_) {}
    }
    final seen = <String>{};
    for (final s in subjects) {
      final code = s.subjectCode.trim().toLowerCase();
      if (code.isEmpty || seen.contains(code)) continue;
      seen.add(code);
      await Fs.add(
        boxName,
        TeacherSubject(
          teacherId: id,
          subjectCode: s.subjectCode.trim(),
          subjectName: s.subjectName.trim(),
        ).toMap(),
      );
    }
  }

  static Future<void> clearForTeacher(String teacherId) async {
    await setForTeacher(teacherId, []);
  }
}
