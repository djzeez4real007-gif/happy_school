import '../database/fs.dart';
import '../models/teacher.dart';

class TeacherStorage {
  static const String boxName = 'teachers';

  static Future<void> addTeacher(Teacher teacher) async {
    final existing = await getTeacher(teacher.staffId);
    if (existing != null) {
      await updateTeacherByStaffId(teacher.staffId, teacher);
      return;
    }
    await Fs.add(boxName, teacher.toMap());
  }

  static Future<List<Teacher>> getTeachers() async {
    final list = <Teacher>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(Teacher.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<Teacher?> getTeacher(String staffId) async {
    final wanted = staffId.trim().toLowerCase();
    for (final t in await getTeachers()) {
      if (t.staffId.trim().toLowerCase() == wanted) return t;
    }
    return null;
  }

  /// Async index lookup (Firestore has no stable local index).
  static Future<int> indexOfStaffId(String staffId) async {
    final wanted = staffId.trim().toLowerCase();
    final rows = await Fs.getAll(boxName);
    for (int i = 0; i < rows.length; i++) {
      try {
        final t = Teacher.fromMap(Map<String, dynamic>.from(rows[i]));
        if (t.staffId.trim().toLowerCase() == wanted) return i;
      } catch (_) {}
    }
    return -1;
  }

  static Future<void> deleteTeacherByStaffId(String staffId) async {
    final rows = await Fs.getAll(boxName);
    final wanted = staffId.trim().toLowerCase();
    for (final r in rows) {
      try {
        final t = Teacher.fromMap(Map<String, dynamic>.from(r));
        if (t.staffId.trim().toLowerCase() == wanted) {
          final id = r['_docId']?.toString();
          if (id != null) await Fs.delete(boxName, id);
          return;
        }
      } catch (_) {}
    }
  }

  static Future<void> deleteTeacher(int index) async {
    await Fs.deleteAt(boxName, index);
  }

  static Future<void> updateTeacher(int index, Teacher teacher) async {
    await updateTeacherByStaffId(teacher.staffId, teacher);
  }

  static Future<void> updateTeacherByStaffId(
    String originalStaffId,
    Teacher teacher,
  ) async {
    final rows = await Fs.getAll(boxName);
    final wanted = originalStaffId.trim().toLowerCase();
    for (final r in rows) {
      try {
        final t = Teacher.fromMap(Map<String, dynamic>.from(r));
        if (t.staffId.trim().toLowerCase() == wanted) {
          final id = r['_docId']?.toString();
          if (id != null) {
            await Fs.set(boxName, id, teacher.toMap());
            return;
          }
        }
      } catch (_) {}
    }
    await Fs.add(boxName, teacher.toMap());
  }
}
