import '../database/fs.dart';
import '../models/school_profile.dart';

class SchoolProfileStorage {
  static const boxName = 'school_profile';
  static const _key = 'profile';

  static Future<SchoolProfile> load() async {
    final raw = await Fs.getSingleton(boxName, _key);
    if (raw != null) {
      try {
        return SchoolProfile.fromMap(Map<String, dynamic>.from(raw));
      } catch (_) {}
    }
    return SchoolProfile.defaults;
  }

  static Future<void> save(SchoolProfile profile) async {
    await Fs.setSingleton(boxName, _key, profile.toMap());
  }
}
