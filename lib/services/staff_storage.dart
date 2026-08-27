import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/staff_member.dart';

class StaffStorage {
  static const boxName = 'non_teaching_staff';

  static Box get _box => Hive.box(boxName);

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static List<StaffMember> getAll({bool activeOnly = false}) {
    final list = _box.values
        .map((e) => StaffMember.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    if (activeOnly) return list.where((s) => s.active).toList();
    return list;
  }

  static Future<void> add(StaffMember s) async {
    await _box.add(s.toMap());
  }

  static Future<void> update(int index, StaffMember s) async {
    await _box.putAt(index, s.toMap());
  }

  static Future<void> deleteAt(int index) async {
    await _box.deleteAt(index);
  }

  static int indexOfId(String id) {
    final values = _box.values.toList();
    for (var i = 0; i < values.length; i++) {
      final m = Map<String, dynamic>.from(values[i] as Map);
      if (m['id']?.toString() == id) return i;
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
