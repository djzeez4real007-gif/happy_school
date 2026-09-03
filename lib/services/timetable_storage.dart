import 'package:hive_flutter/hive_flutter.dart';

import '../models/timetable.dart';

class TimetableStorage {
  static const String boxName = "timetables";

  // ============================================================
  // OPEN TIMETABLE BOX
  // ============================================================

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      try {
        return Hive.box<Map>(boxName);
      } catch (_) {
        return Hive.box(boxName);
      }
    }
    return await Hive.openBox<Map>(boxName);
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

  static String _normPeriod(String p) {
    final m = RegExp(r'period\s*(\d+)', caseSensitive: false).firstMatch(p.trim());
    if (m != null) return 'Period ${m.group(1)}';
    return p.trim().toLowerCase();
  }

  static bool _sameSlot(Timetable a, Timetable b) {
    return a.day.trim().toLowerCase() == b.day.trim().toLowerCase() &&
        _normPeriod(a.period) == _normPeriod(b.period) &&
        a.className.trim().toLowerCase() == b.className.trim().toLowerCase() &&
        a.session.trim().toLowerCase() == b.session.trim().toLowerCase() &&
        a.term.trim().toLowerCase() == b.term.trim().toLowerCase();
  }

  /// Add or replace existing entry for same day/period/class/session/term.
  static Future<void> addTimetable(Timetable timetable) async {
    final box = await _getBox();
    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw == null) continue;
      try {
        final existing = Timetable.fromMap(Map<String, dynamic>.from(raw));
        if (_sameSlot(existing, timetable)) {
          await box.putAt(i, timetable.toMap());
          return;
        }
      } catch (_) {}
    }
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

  /// Copy all entries from [sourceClass] to each target class.
  /// Skips a target slot if the same day+period already exists for that class
  /// (unless [overwrite] is true — then those are left as-is and only missing
  /// slots are filled; we never delete existing).
  static Future<int> copyClassToClasses({
    required String sourceClass,
    required List<String> targetClasses,
    bool skipExistingSlots = true,
  }) async {
    final source = sourceClass.trim();
    final targets = targetClasses
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != source.toLowerCase())
        .toSet()
        .toList();
    if (source.isEmpty || targets.isEmpty) return 0;

    final all = await getTimetables();
    final sourceEntries = all
        .where((e) => e.className.trim().toLowerCase() == source.toLowerCase())
        .toList();
    if (sourceEntries.isEmpty) return 0;

    final box = await _getBox();
    var added = 0;
    var n = 0;

    for (final target in targets) {
      final existing = all
          .where((e) => e.className.trim().toLowerCase() == target.toLowerCase())
          .toList();
      for (final src in sourceEntries) {
        if (skipExistingSlots) {
          final exists = existing.any(
            (e) =>
                e.day == src.day &&
                e.period.trim().toLowerCase() == src.period.trim().toLowerCase(),
          );
          if (exists) continue;
        }
        n++;
        final copy = src.copyWith(
          id: '${generateId()}_$n',
          className: target,
        );
        await box.add(copy.toMap());
        added++;
      }
    }
    return added;
  }
}
