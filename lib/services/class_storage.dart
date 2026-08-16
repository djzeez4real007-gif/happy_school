import 'package:hive_flutter/hive_flutter.dart';
import '../models/school_class.dart';

class ClassStorage {
  static const String boxName = "classes";

  // ===========================
  // ADD / UPDATE CLASS
  // ===========================
  static Future<void> addClass(SchoolClass schoolClass) async {
    final box = Hive.box<Map>(boxName);

    for (int i = 0; i < box.length; i++) {
      final item = SchoolClass.fromMap(
        Map<String, dynamic>.from(box.getAt(i)!),
      );

      if (item.fullClassName == schoolClass.fullClassName) {
        await box.putAt(i, schoolClass.toMap());
        return;
      }
    }

    await box.add(schoolClass.toMap());
  }

  // ===========================
  // GET ALL CLASSES
  // ===========================
  static Future<List<SchoolClass>> getClasses() async {
    final box = Hive.box<Map>(boxName);

    return box.values
        .map((e) => SchoolClass.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ===========================
  // GET ONE CLASS
  // ===========================
  static Future<SchoolClass?> getClass(String className) async {
    final box = Hive.box<Map>(boxName);

    for (final item in box.values) {
      final schoolClass = SchoolClass.fromMap(Map<String, dynamic>.from(item));

      if (schoolClass.fullClassName == className) {
        return schoolClass;
      }
    }

    return null;
  }

  // ===========================
  // DELETE CLASS
  // ===========================
  static Future<void> deleteClass(int index) async {
    final box = Hive.box<Map>(boxName);
    await box.deleteAt(index);
  }

  // ===========================
  // UPDATE CLASS
  // ===========================
  static Future<void> updateClass(int index, SchoolClass schoolClass) async {
    final box = Hive.box<Map>(boxName);
    await box.putAt(index, schoolClass.toMap());
  }

  // ===========================
  // TOTAL CLASSES
  // ===========================
  static Future<int> getTotalClasses() async {
    final box = Hive.box<Map>(boxName);
    return box.length;
  }
}
