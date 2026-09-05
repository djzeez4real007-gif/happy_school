import 'dart:math';

import '../database/fs.dart';
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

  static String generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static Future<StudentPortalAccount?> getByAdmission(String admissionNo) async {
    final target = admissionNo.trim().toLowerCase();
    for (final raw in await Fs.getAll(boxName)) {
      try {
        final a = StudentPortalAccount.fromMap(Map<String, dynamic>.from(raw));
        if (a.admissionNo.trim().toLowerCase() == target) return a;
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> hasAccount(String admissionNo) async {
    return (await getByAdmission(admissionNo)) != null;
  }

  static Future<String> setPassword({
    required String admissionNo,
    required String fullName,
    String? plainPassword,
  }) async {
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

    final rows = await Fs.getAll(boxName);
    final target = admissionNo.trim().toLowerCase();
    for (final raw in rows) {
      try {
        final a = StudentPortalAccount.fromMap(Map<String, dynamic>.from(raw));
        if (a.admissionNo.trim().toLowerCase() == target) {
          final id = raw['_docId']?.toString();
          if (id != null) {
            await Fs.set(boxName, id, account.toMap());
            return plain;
          }
        }
      } catch (_) {}
    }
    await Fs.add(boxName, account.toMap());
    return plain;
  }
}
