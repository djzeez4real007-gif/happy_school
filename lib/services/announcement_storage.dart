import 'package:hive_flutter/hive_flutter.dart';

import '../models/announcement.dart';

class AnnouncementStorage {
  static const boxName = 'announcements';

  /// Always reuse the already-open box (typed or untyped).
  static Future<Box> _box() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    // Prefer untyped open so it matches most existing projects
    return Hive.openBox(boxName);
  }

  static Future<List<Announcement>> getAnnouncements() async {
    final box = await _box();
    final list = <Announcement>[];
    for (final raw in box.values) {
      try {
        if (raw is Map) {
          list.add(Announcement.fromMap(Map<String, dynamic>.from(raw)));
        }
      } catch (_) {}
    }
    return list;
  }

  static Future<void> addAnnouncement(Announcement item) async {
    final box = await _box();
    await box.add(Map<String, dynamic>.from(item.toMap()));
    try {
      await box.flush();
    } catch (_) {}
  }

  static Future<void> updateAnnouncement(int index, Announcement item) async {
    final box = await _box();
    if (index < 0 || index >= box.length) {
      await addAnnouncement(item);
      return;
    }
    await box.putAt(index, Map<String, dynamic>.from(item.toMap()));
    try {
      await box.flush();
    } catch (_) {}
  }

  static Future<void> deleteAnnouncement(int index) async {
    final box = await _box();
    if (index < 0 || index >= box.length) return;
    await box.deleteAt(index);
    try {
      await box.flush();
    } catch (_) {}
  }
}
