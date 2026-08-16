// lib/services/attendance_storage.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance.dart';

class AttendanceStorage {
  static const String _key = "attendance_records";

  static Future<List<Attendance>> getAttendance() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map((item) => Attendance.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Attendance> attendance) async {
    final prefs = await SharedPreferences.getInstance();

    final data = attendance.map((e) => e.toJson()).toList();

    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<void> saveAttendance(Attendance attendance) async {
    final records = await getAttendance();

    final existingIndex = records.indexWhere(
      (item) =>
          item.admissionNo == attendance.admissionNo &&
          item.date == attendance.date &&
          item.session == attendance.session &&
          item.term == attendance.term,
    );

    if (existingIndex >= 0) {
      records[existingIndex] = attendance;
    } else {
      records.add(attendance);
    }

    await _saveAll(records);
  }

  static Future<void> saveMany(List<Attendance> attendance) async {
    final records = await getAttendance();

    for (final item in attendance) {
      final existingIndex = records.indexWhere(
        (record) =>
            record.admissionNo == item.admissionNo &&
            record.date == item.date &&
            record.session == item.session &&
            record.term == item.term,
      );

      if (existingIndex >= 0) {
        records[existingIndex] = item;
      } else {
        records.add(item);
      }
    }

    await _saveAll(records);
  }

  static Future<List<Attendance>> getByClassAndDate({
    required String className,
    required String date,
    required String session,
    required String term,
  }) async {
    final records = await getAttendance();

    return records.where((item) {
      return item.className == className &&
          item.date == date &&
          item.session == session &&
          item.term == term;
    }).toList();
  }

  static Future<List<Attendance>> getStudentAttendance(
    String admissionNo,
  ) async {
    final records = await getAttendance();

    return records.where((item) => item.admissionNo == admissionNo).toList();
  }

  static Future<void> deleteAttendance(String id) async {
    final records = await getAttendance();

    records.removeWhere((item) => item.id == id);

    await _saveAll(records);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
