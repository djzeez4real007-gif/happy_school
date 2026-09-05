import '../database/fs.dart';
import '../models/timetable.dart';

class TimetableStorage {
  static const String boxName = 'timetables';

  static Future<List<Timetable>> getTimetables() async {
    final list = <Timetable>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(Timetable.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static String _normPeriod(String p) => p.trim().toLowerCase();

  static bool _sameSlot(Timetable a, Timetable b) {
    return a.className.trim().toLowerCase() == b.className.trim().toLowerCase() &&
        a.day.trim().toLowerCase() == b.day.trim().toLowerCase() &&
        _normPeriod(a.period) == _normPeriod(b.period) &&
        a.session.trim().toLowerCase() == b.session.trim().toLowerCase() &&
        a.term.trim().toLowerCase() == b.term.trim().toLowerCase();
  }

  static Future<void> addTimetable(Timetable timetable) async {
    final all = await getTimetables();
    final rows = await Fs.getAll(boxName);
    for (int i = 0; i < all.length; i++) {
      if (_sameSlot(all[i], timetable)) {
        final id = rows[i]['_docId']?.toString();
        if (id != null) {
          await Fs.set(boxName, id, timetable.toMap());
          return;
        }
      }
    }
    await Fs.add(boxName, timetable.toMap());
  }

  static Future<void> updateTimetable(int index, Timetable timetable) async {
    await Fs.putAt(boxName, index, timetable.toMap());
  }

  static Future<void> deleteTimetable(int index) async {
    await Fs.deleteAt(boxName, index);
  }

  static Future<List<Timetable>> getByDay(String day) async {
    final d = day.trim().toLowerCase();
    return (await getTimetables())
        .where((t) => t.day.trim().toLowerCase() == d)
        .toList();
  }

  static Future<List<Timetable>> getByClass(String className) async {
    final c = className.trim().toLowerCase();
    return (await getTimetables())
        .where((t) => t.className.trim().toLowerCase() == c)
        .toList();
  }

  static Future<List<Timetable>> getBySession(String session) async {
    final s = session.trim().toLowerCase();
    return (await getTimetables())
        .where((t) => t.session.trim().toLowerCase() == s)
        .toList();
  }

  static Future<List<Timetable>> getByTerm(String term) async {
    final te = term.trim().toLowerCase();
    return (await getTimetables())
        .where((t) => t.term.trim().toLowerCase() == te)
        .toList();
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// Copy all entries from [sourceClass] to each target class.
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
        await addTimetable(copy);
        added++;
      }
    }
    return added;
  }
}
