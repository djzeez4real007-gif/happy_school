import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/school_licence.dart';

class LicenceStorage {
  static const boxName = 'school_licence';
  static const _key = 'licence';

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Future<SchoolLicence> load() async {
    await open();
    final box = Hive.box(boxName);
    final raw = box.get(_key);
    if (raw is Map) {
      try {
        return SchoolLicence.fromMap(Map<String, dynamic>.from(raw));
      } catch (e) {
        debugPrint('Licence load error: $e');
      }
    }
    final trial = SchoolLicence.defaults;
    await save(trial);
    return trial;
  }

  static Future<void> save(SchoolLicence licence) async {
    await open();
    await Hive.box(boxName).put(_key, licence.toMap());
  }
}
