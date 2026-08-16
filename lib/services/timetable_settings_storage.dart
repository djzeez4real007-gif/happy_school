import 'package:hive_flutter/hive_flutter.dart';

class TimetableSettingsStorage {
  static const String boxName = "timetable_settings";

  static const String _keyMondayThursdayPeriods = "mondayThursdayPeriods";
  static const String _keyFridayPeriods = "fridayPeriods";
  static const String _keyShortBreakEnabled = "shortBreakEnabled";
  static const String _keyShortBreakAfterPeriod = "shortBreakAfterPeriod";
  static const String _keyShortBreakDuration = "shortBreakDuration";
  static const String _keyLongBreakEnabled = "longBreakEnabled";
  static const String _keyLongBreakAfterPeriod = "longBreakAfterPeriod";
  static const String _keyLongBreakDuration = "longBreakDuration";

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    final box = Hive.box(boxName);

    if (box.get(_keyMondayThursdayPeriods) == null) {
      await box.put(_keyMondayThursdayPeriods, _defaultMondayThursdayPeriods());
    }

    if (box.get(_keyFridayPeriods) == null) {
      await box.put(_keyFridayPeriods, _defaultFridayPeriods());
    }

    if (box.get(_keyShortBreakEnabled) == null) {
      await box.put(_keyShortBreakEnabled, true);
    }

    if (box.get(_keyShortBreakAfterPeriod) == null) {
      await box.put(_keyShortBreakAfterPeriod, 2);
    }

    if (box.get(_keyShortBreakDuration) == null) {
      await box.put(_keyShortBreakDuration, 15);
    }

    if (box.get(_keyLongBreakEnabled) == null) {
      await box.put(_keyLongBreakEnabled, true);
    }

    if (box.get(_keyLongBreakAfterPeriod) == null) {
      await box.put(_keyLongBreakAfterPeriod, 5);
    }

    if (box.get(_keyLongBreakDuration) == null) {
      await box.put(_keyLongBreakDuration, 30);
    }
  }

  static List<Map<String, dynamic>> _defaultMondayThursdayPeriods() {
    return [
      {"period": 1, "start": "8:00 AM", "end": "8:45 AM"},
      {"period": 2, "start": "8:45 AM", "end": "9:30 AM"},
      {"period": 3, "start": "9:30 AM", "end": "10:15 AM"},
      {"period": 4, "start": "10:15 AM", "end": "11:00 AM"},
      {"period": 5, "start": "11:00 AM", "end": "11:45 AM"},
      {"period": 6, "start": "11:45 AM", "end": "12:30 PM"},
      {"period": 7, "start": "12:30 PM", "end": "1:15 PM"},
      {"period": 8, "start": "1:15 PM", "end": "2:00 PM"},
    ];
  }

  static List<Map<String, dynamic>> _defaultFridayPeriods() {
    return [
      {"period": 1, "start": "8:00 AM", "end": "8:40 AM"},
      {"period": 2, "start": "8:40 AM", "end": "9:20 AM"},
      {"period": 3, "start": "9:20 AM", "end": "10:00 AM"},
      {"period": 4, "start": "10:00 AM", "end": "10:40 AM"},
      {"period": 5, "start": "10:40 AM", "end": "11:20 AM"},
      {"period": 6, "start": "11:20 AM", "end": "12:00 PM"},
      {"period": 7, "start": "12:00 PM", "end": "12:40 PM"},
      {"period": 8, "start": "12:40 PM", "end": "1:20 PM"},
    ];
  }

  static List<Map<String, dynamic>> _safePeriods(dynamic value) {
    if (value is! List) {
      return _defaultMondayThursdayPeriods();
    }

    final result = <Map<String, dynamic>>[];

    for (var i = 0; i < value.length; i++) {
      final item = value[i];

      if (item is Map) {
        final periodNumber = _safeInt(item["period"], i + 1);

        final start = _safeString(item["start"], "");

        final end = _safeString(item["end"], "");

        result.add({"period": periodNumber, "start": start, "end": end});
      }
    }

    if (result.isEmpty) {
      return _defaultMondayThursdayPeriods();
    }

    return result;
  }

  static List<Map<String, dynamic>> _safeFridayPeriods(dynamic value) {
    if (value is! List) {
      return _defaultFridayPeriods();
    }

    final result = <Map<String, dynamic>>[];

    for (var i = 0; i < value.length; i++) {
      final item = value[i];

      if (item is Map) {
        result.add({
          "period": _safeInt(item["period"], i + 1),
          "start": _safeString(item["start"], ""),
          "end": _safeString(item["end"], ""),
        });
      }
    }

    if (result.isEmpty) {
      return _defaultFridayPeriods();
    }

    return result;
  }

  static int _safeInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static bool _safeBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == "true";
    }

    return fallback;
  }

  static String _safeString(dynamic value, String fallback) {
    if (value is String) {
      return value;
    }

    return fallback;
  }

  static Future<List<Map<String, dynamic>>> getMondayThursdayPeriods() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safePeriods(box.get(_keyMondayThursdayPeriods));
  }

  static Future<List<Map<String, dynamic>>> getFridayPeriods() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeFridayPeriods(box.get(_keyFridayPeriods));
  }

  static Future<bool> getShortBreakEnabled() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeBool(box.get(_keyShortBreakEnabled), true);
  }

  static Future<int> getShortBreakAfterPeriod() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeInt(box.get(_keyShortBreakAfterPeriod), 2);
  }

  static Future<int> getShortBreakDuration() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeInt(box.get(_keyShortBreakDuration), 15);
  }

  static Future<bool> getLongBreakEnabled() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeBool(box.get(_keyLongBreakEnabled), true);
  }

  static Future<int> getLongBreakAfterPeriod() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeInt(box.get(_keyLongBreakAfterPeriod), 5);
  }

  static Future<int> getLongBreakDuration() async {
    await initialize();

    final box = Hive.box(boxName);

    return _safeInt(box.get(_keyLongBreakDuration), 30);
  }

  static Future<void> saveSettings({
    required List<Map<String, dynamic>> mondayThursdayPeriods,
    required List<Map<String, dynamic>> fridayPeriods,
    required bool shortBreakEnabled,
    required int shortBreakAfterPeriod,
    required int shortBreakDuration,
    required bool longBreakEnabled,
    required int longBreakAfterPeriod,
    required int longBreakDuration,
  }) async {
    await initialize();

    final box = Hive.box(boxName);

    await box.put(_keyMondayThursdayPeriods, mondayThursdayPeriods);

    await box.put(_keyFridayPeriods, fridayPeriods);

    await box.put(_keyShortBreakEnabled, shortBreakEnabled);

    await box.put(_keyShortBreakAfterPeriod, shortBreakAfterPeriod);

    await box.put(_keyShortBreakDuration, shortBreakDuration);

    await box.put(_keyLongBreakEnabled, longBreakEnabled);

    await box.put(_keyLongBreakAfterPeriod, longBreakAfterPeriod);

    await box.put(_keyLongBreakDuration, longBreakDuration);
  }

  static Future<void> resetToDefaults() async {
    final box = Hive.box(boxName);

    await box.put(_keyMondayThursdayPeriods, _defaultMondayThursdayPeriods());

    await box.put(_keyFridayPeriods, _defaultFridayPeriods());

    await box.put(_keyShortBreakEnabled, true);
    await box.put(_keyShortBreakAfterPeriod, 2);
    await box.put(_keyShortBreakDuration, 15);

    await box.put(_keyLongBreakEnabled, true);
    await box.put(_keyLongBreakAfterPeriod, 5);
    await box.put(_keyLongBreakDuration, 30);
  }
}
