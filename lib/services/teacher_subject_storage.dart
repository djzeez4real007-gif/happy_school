import 'package:hive_flutter/hive_flutter.dart';

import '../models/teacher_subject.dart';

class TeacherSubjectStorage {
  static const String boxName = 'teacher_subjects';

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _box => Hive.box(boxName);

  static Future<List<TeacherSubject>> getAll() async {
    await open();
    return _box.values
        .map((e) => TeacherSubject.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<TeacherSubject>> forTeacher(String teacherId) async {
    final id = teacherId.trim().toLowerCase();
    if (id.isEmpty) return [];
    final all = await getAll();
    final seen = <String>{};
    final out = <TeacherSubject>[];
    for (final t in all) {
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
    await open();
    final id = teacherId.trim();
    // Remove existing for this teacher
    final toDelete = <int>[];
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw is! Map) continue;
      final t = TeacherSubject.fromMap(Map<String, dynamic>.from(raw));
      if (t.teacherId.trim().toLowerCase() == id.toLowerCase()) {
        toDelete.add(i);
      }
    }
    for (final i in toDelete.reversed) {
      await _box.deleteAt(i);
    }
    final seen = <String>{};
    for (final s in subjects) {
      final code = s.subjectCode.trim().toLowerCase();
      if (code.isEmpty || seen.contains(code)) continue;
      seen.add(code);
      await _box.add(
        TeacherSubject(
          teacherId: id,
          subjectCode: s.subjectCode.trim(),
          subjectName: s.subjectName.trim(),
        ).toMap(),
      );
    }
    await _box.flush();
  }

  static Future<void> clearForTeacher(String teacherId) async {
    await setForTeacher(teacherId, []);
  }
}
