import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/school_profile.dart';

class SchoolProfileStorage {
  static const boxName = 'school_profile';
  static const _key = 'profile';

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Future<SchoolProfile> load() async {
    await open();
    final box = Hive.box(boxName);
    final raw = box.get(_key);
    if (raw is Map) {
      try {
        return SchoolProfile.fromMap(Map<String, dynamic>.from(raw));
      } catch (e) {
        debugPrint('SchoolProfile load error: $e');
      }
    }
    return SchoolProfile.defaults;
  }

  static Future<void> save(SchoolProfile profile) async {
    await open();
    final box = Hive.box(boxName);
    await box.put(_key, profile.toMap());
  }
}
