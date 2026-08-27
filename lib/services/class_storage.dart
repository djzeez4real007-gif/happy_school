import 'package:hive_flutter/hive_flutter.dart';
import '../models/school_class.dart';

class ClassStorage {
  static const String boxName = 'classes';

  /// Must match HiveDatabase: openBox<Map>('classes')
  static Box<Map> _box() => Hive.box<Map>(boxName);

  static SchoolClass _from(Map raw) {
    return SchoolClass.fromMap(Map<String, dynamic>.from(raw));
  }

  static Future<void> addClass(SchoolClass schoolClass) async {
    final box = _box();
    final target = schoolClass.fullClassName.trim().toLowerCase();

    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw == null) continue;
      final item = _from(raw);
      if (item.fullClassName.trim().toLowerCase() == target) {
        await box.putAt(i, schoolClass.toMap());
        await box.flush();
        return;
      }
    }

    await box.add(schoolClass.toMap());
    await box.flush();
  }

  static Future<List<SchoolClass>> getClasses() async {
    final box = _box();
    final list = <SchoolClass>[];
    for (final raw in box.values) {
      try {
        final c = _from(raw);
        if (c.fullClassName.trim().isNotEmpty) list.add(c);
      } catch (_) {}
    }
    list.sort(
      (a, b) =>
          a.fullClassName.toLowerCase().compareTo(b.fullClassName.toLowerCase()),
    );
    return list;
  }

  static Future<SchoolClass?> getClass(String className) async {
    final target = className.trim().toLowerCase();
    for (final c in await getClasses()) {
      if (c.fullClassName.trim().toLowerCase() == target) return c;
    }
    return null;
  }

  static Future<void> deleteClass(int index) async {
    await _box().deleteAt(index);
    await _box().flush();
  }

  static Future<void> updateClass(int index, SchoolClass schoolClass) async {
    await _box().putAt(index, schoolClass.toMap());
    await _box().flush();
  }

  static Future<int> getTotalClasses() async {
    return _box().length;
  }
}
