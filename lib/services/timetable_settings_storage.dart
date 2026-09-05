import '../database/fs.dart';

class TimetableSettingsStorage {
  static const String boxName = 'timetable_settings';
  static const String _doc = 'settings';

  static const _kMon = 'mondayThursdayPeriods';
  static const _kFri = 'fridayPeriods';
  static const _kShortEn = 'shortBreakEnabled';
  static const _kShortAfter = 'shortBreakAfterPeriod';
  static const _kShortDur = 'shortBreakDuration';
  static const _kLongEn = 'longBreakEnabled';
  static const _kLongAfter = 'longBreakAfterPeriod';
  static const _kLongDur = 'longBreakDuration';

  static Future<Map<String, dynamic>> _data() async {
    final raw = await Fs.getSingleton(boxName, _doc);
    if (raw == null || raw.isEmpty) {
      final seed = {
        _kMon: _defaultMon(),
        _kFri: _defaultFri(),
        _kShortEn: true,
        _kShortAfter: 2,
        _kShortDur: 15,
        _kLongEn: true,
        _kLongAfter: 4,
        _kLongDur: 30,
      };
      await Fs.setSingleton(boxName, _doc, seed);
      return seed;
    }
    return raw;
  }

  static Future<void> initialize() async => _data();

  static List<Map<String, dynamic>> _defaultMon() => [
        {'name': 'Period 1', 'start': '08:00', 'end': '08:40'},
        {'name': 'Period 2', 'start': '08:40', 'end': '09:20'},
        {'name': 'Period 3', 'start': '09:20', 'end': '10:00'},
        {'name': 'Period 4', 'start': '10:20', 'end': '11:00'},
        {'name': 'Period 5', 'start': '11:00', 'end': '11:40'},
        {'name': 'Period 6', 'start': '11:40', 'end': '12:20'},
        {'name': 'Period 7', 'start': '13:00', 'end': '13:40'},
        {'name': 'Period 8', 'start': '13:40', 'end': '14:20'},
      ];

  static List<Map<String, dynamic>> _defaultFri() => [
        {'name': 'Period 1', 'start': '08:00', 'end': '08:40'},
        {'name': 'Period 2', 'start': '08:40', 'end': '09:20'},
        {'name': 'Period 3', 'start': '09:20', 'end': '10:00'},
        {'name': 'Period 4', 'start': '10:20', 'end': '11:00'},
        {'name': 'Period 5', 'start': '11:00', 'end': '11:40'},
        {'name': 'Period 6', 'start': '11:40', 'end': '12:20'},
      ];

  static List<Map<String, dynamic>> _safePeriods(dynamic value, List<Map<String, dynamic>> fallback) {
    if (value is! List) return fallback;
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map) {
        result.add({
          'name': '${item['name'] ?? ''}',
          'start': '${item['start'] ?? ''}',
          'end': '${item['end'] ?? ''}',
        });
      }
    }
    return result.isEmpty ? fallback : result;
  }

  static Future<List<Map<String, dynamic>>> getMondayThursdayPeriods() async {
    final d = await _data();
    return _safePeriods(d[_kMon], _defaultMon());
  }

  static Future<List<Map<String, dynamic>>> getFridayPeriods() async {
    final d = await _data();
    return _safePeriods(d[_kFri], _defaultFri());
  }

  static Future<bool> getShortBreakEnabled() async =>
      (await _data())[_kShortEn] == true;
  static Future<int> getShortBreakAfterPeriod() async =>
      int.tryParse('${(await _data())[_kShortAfter]}') ?? 2;
  static Future<int> getShortBreakDuration() async =>
      int.tryParse('${(await _data())[_kShortDur]}') ?? 15;
  static Future<bool> getLongBreakEnabled() async =>
      (await _data())[_kLongEn] == true;
  static Future<int> getLongBreakAfterPeriod() async =>
      int.tryParse('${(await _data())[_kLongAfter]}') ?? 4;
  static Future<int> getLongBreakDuration() async =>
      int.tryParse('${(await _data())[_kLongDur]}') ?? 30;

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
    await Fs.setSingleton(boxName, _doc, {
      _kMon: mondayThursdayPeriods,
      _kFri: fridayPeriods,
      _kShortEn: shortBreakEnabled,
      _kShortAfter: shortBreakAfterPeriod,
      _kShortDur: shortBreakDuration,
      _kLongEn: longBreakEnabled,
      _kLongAfter: longBreakAfterPeriod,
      _kLongDur: longBreakDuration,
    });
  }

  static Future<void> resetToDefaults() async {
    await Fs.setSingleton(boxName, _doc, {
      _kMon: _defaultMon(),
      _kFri: _defaultFri(),
      _kShortEn: true,
      _kShortAfter: 2,
      _kShortDur: 15,
      _kLongEn: true,
      _kLongAfter: 4,
      _kLongDur: 30,
    });
  }
}
