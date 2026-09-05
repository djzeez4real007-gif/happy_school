import 'package:flutter/foundation.dart';
import '../database/fs.dart';
import '../models/school_licence.dart';

class LicenceStorage {
  static const boxName = 'school_licence';
  static const _key = 'licence';

  static Future<SchoolLicence> load() async {
    final raw = await Fs.getSingleton(boxName, _key);
    if (raw != null) {
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
    await Fs.setSingleton(boxName, _key, licence.toMap());
  }
}
