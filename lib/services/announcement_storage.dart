import '../database/fs.dart';
import '../models/announcement.dart';

class AnnouncementStorage {
  static const boxName = 'announcements';

  static Future<List<Announcement>> getAnnouncements() async {
    final list = <Announcement>[];
    for (final raw in await Fs.getAll(boxName)) {
      try {
        list.add(Announcement.fromMap(Map<String, dynamic>.from(raw)));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> addAnnouncement(Announcement item) async {
    await Fs.add(boxName, Map<String, dynamic>.from(item.toMap()));
  }

  static Future<void> updateAnnouncement(int index, Announcement item) async {
    await Fs.putAt(boxName, index, Map<String, dynamic>.from(item.toMap()));
  }

  static Future<void> deleteAnnouncement(int index) async {
    await Fs.deleteAt(boxName, index);
  }
}
