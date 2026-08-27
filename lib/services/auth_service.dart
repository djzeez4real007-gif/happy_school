import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';
import 'user_storage.dart';
import 'student_portal_storage.dart';
import 'student_storage.dart';
import 'audit_log_storage.dart';

class AuthService {
  static const String _sessionBoxName = 'auth_session';
  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static String get currentRole => _currentUser?.role ?? '';
  static String get currentName => _currentUser?.fullName ?? '';

  /// Simple hash so passwords are not stored as plain text.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  static Future<void> initSession() async {
    if (!Hive.isBoxOpen(_sessionBoxName)) {
      await Hive.openBox(_sessionBoxName);
    }
    final box = Hive.box(_sessionBoxName);
    final userId = box.get('userId')?.toString();
    if (userId == null || userId.isEmpty) return;

    final loginType = box.get('loginType')?.toString() ?? 'staff';
    if (loginType == 'student' || userId.startsWith('student_')) {
      final adm = box.get('studentAdmissionNo')?.toString() ??
          userId.replaceFirst('student_', '');
      final portal = await StudentPortalStorage.getByAdmission(adm);
      if (portal != null && portal.isActive) {
        String fullName = portal.fullName;
        try {
          final students = await StudentStorage.getStudents();
          final match = students.where(
            (s) =>
                s.admissionNo.trim().toLowerCase() ==
                adm.trim().toLowerCase(),
          );
          if (match.isNotEmpty) fullName = match.first.fullName;
        } catch (_) {}
        _currentUser = AppUser(
          id: 'student_$adm',
          fullName: fullName.isNotEmpty ? fullName : adm,
          username: adm,
          passwordHash: portal.passwordHash,
          role: 'student',
          isActive: true,
          linkedAdmissionNos: adm,
        );
      } else {
        await box.clear();
      }
    } else {
      final user = await UserStorage.getById(userId);
      if (user != null && user.isActive) {
        _currentUser = user;
      } else {
        await box.clear();
      }
    }
  }

  /// Seed default admin if no users exist.
  /// Username: admin   Password: admin123
  static Future<void> seedDefaultAdmin() async {
    final count = await UserStorage.count();
    if (count > 0) return;

    final admin = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: 'System Administrator',
      username: 'admin',
      passwordHash: hashPassword('admin123'),
      role: 'admin',
      isActive: true,
    );

    await UserStorage.addUser(admin);
  }

  static Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final user = await UserStorage.getByUsernameExact(username.trim());

    if (user != null) {
      if (!user.isActive) {
        throw Exception('This account has been disabled');
      }
      final hash = hashPassword(password);
      if (hash != user.passwordHash) {
        throw Exception('Invalid username or password');
      }
      _currentUser = user;
      final box = Hive.box(_sessionBoxName);
      await box.put('userId', user.id);
      await box.put('loginType', 'staff');
      return user;
    }

    // Student portal: username = admission number
    final portal = await StudentPortalStorage.getByAdmission(username.trim());
    if (portal == null) {
      throw Exception('Invalid username or password');
    }
    if (!portal.isActive) {
      throw Exception('This student portal account has been disabled');
    }
    final hash = hashPassword(password);
    if (hash != portal.passwordHash) {
      throw Exception('Invalid username or password');
    }

    String fullName = portal.fullName;
    try {
      final students = await StudentStorage.getStudents();
      final match = students.where(
        (s) =>
            s.admissionNo.trim().toLowerCase() ==
            portal.admissionNo.trim().toLowerCase(),
      );
      if (match.isNotEmpty) fullName = match.first.fullName;
    } catch (_) {}

    final studentUser = AppUser(
      id: 'student_${portal.admissionNo}',
      fullName: fullName.isNotEmpty ? fullName : portal.admissionNo,
      username: portal.admissionNo,
      passwordHash: portal.passwordHash,
      role: 'student',
      isActive: true,
      linkedAdmissionNos: portal.admissionNo,
    );
    _currentUser = studentUser;
    final box = Hive.box(_sessionBoxName);
    await box.put('userId', studentUser.id);
    await box.put('loginType', 'student');
    await box.put('studentAdmissionNo', portal.admissionNo);
    return studentUser;
  }

  static Future<void> logout() async {
    _currentUser = null;
    if (Hive.isBoxOpen(_sessionBoxName)) {
      await Hive.box(_sessionBoxName).clear();
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not logged in');

    if (hashPassword(currentPassword) != user.passwordHash) {
      throw Exception('Current password is incorrect');
    }

    if (newPassword.trim().length < 4) {
      throw Exception('New password must be at least 4 characters');
    }

    final updated = user.copyWith(passwordHash: hashPassword(newPassword));
    await UserStorage.updateUser(user.id, updated);
    _currentUser = updated;
  }
}
