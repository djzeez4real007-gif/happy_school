import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/announcement.dart';

class AnnouncementStorage {
  static const String key = "announcements";

  static Future<List<Announcement>> getAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(key);

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded
        .map((e) => Announcement.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveAnnouncements(
    List<Announcement> announcements,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = jsonEncode(announcements.map((e) => e.toMap()).toList());

    await prefs.setString(key, data);
  }

  static Future<void> addAnnouncement(Announcement announcement) async {
    final list = await getAnnouncements();

    list.add(announcement);

    await saveAnnouncements(list);
  }

  static Future<void> updateAnnouncement(
    int index,
    Announcement announcement,
  ) async {
    final list = await getAnnouncements();

    list[index] = announcement;

    await saveAnnouncements(list);
  }

  static Future<void> deleteAnnouncement(int index) async {
    final list = await getAnnouncements();

    list.removeAt(index);

    await saveAnnouncements(list);
  }
}
