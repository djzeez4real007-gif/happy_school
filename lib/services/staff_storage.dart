import 'package:uuid/uuid.dart';

import '../database/fs.dart';
import '../models/staff_member.dart';

class StaffStorage {
  static const boxName = 'non_teaching_staff';
  static List<StaffMember> _cache = [];

  static Future<void> open() async {
    _cache = await _load();
  }

  static Future<List<StaffMember>> _load() async {
    final list = <StaffMember>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(StaffMember.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  static List<StaffMember> getAll({bool activeOnly = false}) {
    final list = List<StaffMember>.from(_cache);
    if (activeOnly) return list.where((s) => s.active).toList();
    return list;
  }

  static Future<void> add(StaffMember s) async {
    await Fs.add(boxName, s.toMap());
    _cache = await _load();
  }

  static Future<void> update(int index, StaffMember s) async {
    await Fs.putAt(boxName, index, s.toMap());
    _cache = await _load();
  }

  static Future<void> deleteAt(int index) async {
    await Fs.deleteAt(boxName, index);
    _cache = await _load();
  }

  static int indexOfId(String id) {
    for (var i = 0; i < _cache.length; i++) {
      if (_cache[i].id == id) return i;
    }
    return -1;
  }

  static Future<StaffMember> create({
    required String fullName,
    required String post,
    String gender = '',
    String phone = '',
    String email = '',
    String address = '',
    String employmentDate = '',
    String note = '',
    String passport = '',
    String qualification = '',
    String otherQualifications = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    final s = StaffMember(
      id: const Uuid().v4(),
      fullName: fullName.trim(),
      gender: gender,
      phone: phone.trim(),
      email: email.trim(),
      address: address.trim(),
      post: post,
      staffType: 'non_teaching',
      employmentDate: employmentDate,
      passport: passport,
      qualification: qualification,
      otherQualifications: otherQualifications.trim(),
      note: note.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await add(s);
    return s;
  }
}
