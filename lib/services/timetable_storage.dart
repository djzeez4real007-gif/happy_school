import 'package:hive_flutter/hive_flutter.dart';

import '../models/timetable.dart';

class TimetableStorage {
  static const String boxName = "timetable";

  // ============================================================
  // OPEN TIMETABLE BOX
  // ============================================================

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }

    return await Hive.openBox(boxName);
  }

  // ============================================================
  // GET ALL TIMETABLE ENTRIES
  // ============================================================

  static Future<List<Timetable>> getTimetables() async {
    final box = await _getBox();

    return box.values
        .map((e) => Timetable.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ============================================================
  // ADD TIMETABLE ENTRY
  // ============================================================

  static Future<void> addTimetable(Timetable timetable) async {
    final box = await _getBox();

    await box.add(timetable.toMap());
  }

  // ============================================================
  // UPDATE TIMETABLE ENTRY
  // ============================================================

  static Future<void> updateTimetable(int index, Timetable timetable) async {
    final box = await _getBox();

    await box.put(index, timetable.toMap());
  }

  // ============================================================
  // DELETE TIMETABLE ENTRY
  // ============================================================

  static Future<void> deleteTimetable(int index) async {
    final box = await _getBox();

    await box.deleteAt(index);
  }

  // ============================================================
  // GET ENTRIES BY DAY
  // ============================================================

  static Future<List<Timetable>> getByDay(String day) async {
    final timetables = await getTimetables();

    return timetables.where((entry) => entry.day == day).toList();
  }

  // ============================================================
  // GET ENTRIES BY CLASS
  // ============================================================

  static Future<List<Timetable>> getByClass(String className) async {
    final timetables = await getTimetables();

    return timetables.where((entry) => entry.className == className).toList();
  }

  // ============================================================
  // GET ENTRIES BY SESSION
  // ============================================================

  static Future<List<Timetable>> getBySession(String session) async {
    final timetables = await getTimetables();

    return timetables.where((entry) => entry.session == session).toList();
  }

  // ============================================================
  // GET ENTRIES BY TERM
  // ============================================================

  static Future<List<Timetable>> getByTerm(String term) async {
    final timetables = await getTimetables();

    return timetables.where((entry) => entry.term == term).toList();
  }

  // ============================================================
  // GENERATE TIMETABLE ID
  // ============================================================

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
