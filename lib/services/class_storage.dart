import '../database/fs.dart';
import '../models/school_class.dart';

class ClassStorage {
  static const String boxName = 'classes';

  static Future<void> addClass(SchoolClass schoolClass) async {
    final target = schoolClass.fullClassName.trim().toLowerCase();
    final rows = await Fs.getAll(boxName);
    for (final raw in rows) {
      final item = SchoolClass.fromMap(Map<String, dynamic>.from(raw));
      if (item.fullClassName.trim().toLowerCase() == target) {
        final id = raw['_docId']?.toString();
        if (id != null) {
          await Fs.set(boxName, id, schoolClass.toMap());
          return;
        }
      }
    }
    await Fs.add(boxName, schoolClass.toMap());
  }

  static Future<List<SchoolClass>> getClasses() async {
    final list = <SchoolClass>[];
    for (final raw in await Fs.getAll(boxName)) {
      try {
        final c = SchoolClass.fromMap(Map<String, dynamic>.from(raw));
        if (c.fullClassName.trim().isNotEmpty) list.add(c);
      } catch (_) {}
    }
    list.sort((a, b) =>
        a.fullClassName.toLowerCase().compareTo(b.fullClassName.toLowerCase()));
    return list;
  }

  static Future<SchoolClass?> getClass(String className) async {
    final target = className.trim().toLowerCase();
    for (final c in await getClasses()) {
      if (c.fullClassName.trim().toLowerCase() == target) return c;
    }
    return null;
  }

  static Future<void> deleteClass(int index) async => Fs.deleteAt(boxName, index);
  static Future<void> updateClass(int index, SchoolClass schoolClass) async =>
      Fs.putAt(boxName, index, schoolClass.toMap());
  static Future<int> getTotalClasses() async => Fs.count(boxName);
}
