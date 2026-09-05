import '../database/fs.dart';
import '../models/attendance.dart';

class AttendanceStorage {
  static const String boxName = 'attendance';

  static Future<List<Attendance>> getAttendance() async {
    final list = <Attendance>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(Attendance.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> _replaceAll(List<Attendance> attendance) async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
    for (final a in attendance) {
      await Fs.add(boxName, a.toJson());
    }
  }

  static Future<void> saveAttendance(Attendance attendance) async {
    final records = await getAttendance();
    final existingIndex = records.indexWhere((item) =>
        item.admissionNo == attendance.admissionNo &&
        item.date == attendance.date &&
        item.session == attendance.session &&
        item.term == attendance.term);
    if (existingIndex >= 0) {
      records[existingIndex] = attendance;
    } else {
      records.add(attendance);
    }
    await _replaceAll(records);
  }

  static Future<void> saveMany(List<Attendance> attendance) async {
    final records = await getAttendance();
    for (final item in attendance) {
      final existingIndex = records.indexWhere((record) =>
          record.admissionNo == item.admissionNo &&
          record.date == item.date &&
          record.session == item.session &&
          record.term == item.term);
      if (existingIndex >= 0) {
        records[existingIndex] = item;
      } else {
        records.add(item);
      }
    }
    await _replaceAll(records);
  }

  static Future<List<Attendance>> getByClassAndDate({
    required String className,
    required String date,
    required String session,
    required String term,
  }) async {
    final records = await getAttendance();
    return records
        .where((item) =>
            item.className == className &&
            item.date == date &&
            item.session == session &&
            item.term == term)
        .toList();
  }

  static Future<List<Attendance>> getStudentAttendance(String admissionNo) async {
    return (await getAttendance())
        .where((item) => item.admissionNo == admissionNo)
        .toList();
  }

  static Future<void> deleteAttendance(String id) async {
    for (final r in await Fs.getAll(boxName)) {
      try {
        final a = Attendance.fromJson(Map<String, dynamic>.from(r));
        if (a.id == id) {
          final docId = r['_docId']?.toString();
          if (docId != null) await Fs.delete(boxName, docId);
        }
      } catch (_) {}
    }
  }

  static Future<void> clearAll() async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
  }
}
