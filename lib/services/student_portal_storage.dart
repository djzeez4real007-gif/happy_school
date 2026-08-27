import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import 'auth_service.dart';

class StudentPortalAccount {
  final String admissionNo;
  final String passwordHash;
  final bool isActive;
  final String fullName;

  StudentPortalAccount({
    required this.admissionNo,
    required this.passwordHash,
    this.isActive = true,
    this.fullName = '',
  });

  Map<String, dynamic> toMap() => {
        'admissionNo': admissionNo,
        'passwordHash': passwordHash,
        'isActive': isActive,
        'fullName': fullName,
      };

  factory StudentPortalAccount.fromMap(Map map) => StudentPortalAccount(
        admissionNo: map['admissionNo']?.toString() ?? '',
        passwordHash: map['passwordHash']?.toString() ?? '',
        isActive: map['isActive'] != false,
        fullName: map['fullName']?.toString() ?? '',
      );
}

class StudentPortalStorage {
  static const boxName = 'student_portal';

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _box => Hive.box(boxName);

  static Future<StudentPortalAccount?> getByAdmission(String admissionNo) async {
    await open();
    final target = admissionNo.trim().toLowerCase();
    for (final raw in _box.values) {
      if (raw is! Map) continue;
      final a = StudentPortalAccount.fromMap(Map<String, dynamic>.from(raw));
      if (a.admissionNo.trim().toLowerCase() == target) return a;
    }
    return null;
  }

  static Future<bool> hasAccount(String admissionNo) async {
    return (await getByAdmission(admissionNo)) != null;
  }

  /// Creates or updates password. Returns the plain password shown once.
  static Future<String> setPassword({
    required String admissionNo,
    required String fullName,
    String? plainPassword,
  }) async {
    await open();
    final plain = (plainPassword == null || plainPassword.trim().isEmpty)
        ? generatePassword()
        : plainPassword.trim();
    final hash = AuthService.hashPassword(plain);
    final account = StudentPortalAccount(
      admissionNo: admissionNo.trim(),
      passwordHash: hash,
      isActive: true,
      fullName: fullName.trim(),
    );

    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw is! Map) continue;
      final existing =
          StudentPortalAccount.fromMap(Map<String, dynamic>.from(raw));
      if (existing.admissionNo.trim().toLowerCase() ==
          admissionNo.trim().toLowerCase()) {
        await _box.putAt(i, account.toMap());
        await _box.flush();
        return plain;
      }
    }
    await _box.add(account.toMap());
    await _box.flush();
    return plain;
  }

  static Future<void> setActive(String admissionNo, bool active) async {
    await open();
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw is! Map) continue;
      final existing =
          StudentPortalAccount.fromMap(Map<String, dynamic>.from(raw));
      if (existing.admissionNo.trim().toLowerCase() ==
          admissionNo.trim().toLowerCase()) {
        await _box.putAt(
          i,
          existing
              .toMap()
            ..['isActive'] = active,
        );
        await _box.flush();
        return;
      }
    }
  }

  static String generatePassword({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
