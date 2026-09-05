import '../database/fs.dart';
import '../models/student_promotion.dart';

class StudentPromotionStorage {
  static const String boxName = 'student_promotions';

  static Future<List<StudentPromotion>> getPromotions() async {
    final list = <StudentPromotion>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(StudentPromotion.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> savePromotions(List<StudentPromotion> promotions) async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
    for (final p in promotions) {
      await Fs.add(boxName, p.toMap());
    }
  }

  static Future<void> addPromotion(StudentPromotion promotion) async {
    await Fs.add(boxName, promotion.toMap());
  }

  static Future<void> clearPromotions() async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
  }
}
