import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'student_portal_storage.dart';
import 'student_storage.dart';
import 'user_storage.dart';

class AuthService {
  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static String get currentRole => _currentUser?.role ?? '';
  static String get currentName => _currentUser?.fullName ?? '';

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }

  static Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null || userId.isEmpty) return;

    final loginType = prefs.getString('loginType') ?? 'staff';
    if (loginType == 'student' || userId.startsWith('student_')) {
      final adm = prefs.getString('studentAdmissionNo') ??
          userId.replaceFirst('student_', '');
      final portal = await StudentPortalStorage.getByAdmission(adm);
      if (portal != null && portal.isActive) {
        String fullName = portal.fullName;
        try {
          final students = await StudentStorage.getStudents();
          final match = students.where((s) =>
              s.admissionNo.trim().toLowerCase() == adm.trim().toLowerCase());
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
        await prefs.remove('userId');
        await prefs.remove('loginType');
        await prefs.remove('studentAdmissionNo');
      }
    } else {
      final user = await UserStorage.getById(userId);
      if (user != null && user.isActive) {
        _currentUser = user;
      } else {
        await prefs.remove('userId');
        await prefs.remove('loginType');
        await prefs.remove('studentAdmissionNo');
      }
    }
  }

  static Future<void> seedDefaultAdmin() async {
    final count = await UserStorage.count();
    if (count == 0) {
      await UserStorage.addUser(AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: 'System Administrator',
        username: 'admin',
        passwordHash: hashPassword('admin123'),
        role: 'admin',
        isActive: true,
      ));
    }
    await seedVendorAccount();
  }

  static const String vendorUsername = 'hs.vendor';
  static const String vendorPassword = 'V3nd0r@Happy#96';

  static Future<void> seedVendorAccount() async {
    final existing = await UserStorage.getByUsernameExact(vendorUsername);
    if (existing != null) {
      if (existing.role != 'vendor' || !existing.isActive) {
        await UserStorage.updateUser(
          existing.id,
          existing.copyWith(role: 'vendor', isActive: true),
        );
      }
      return;
    }
    await UserStorage.addUser(AppUser(
      id: 'vendor_root_1',
      fullName: 'Vendor Support',
      username: vendorUsername,
      passwordHash: hashPassword(vendorPassword),
      role: 'vendor',
      isActive: true,
    ));
  }

  static Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final user = await UserStorage.getByUsernameExact(username.trim());
    if (user != null) {
      if (!user.isActive) throw Exception('This account has been disabled');
      if (hashPassword(password) != user.passwordHash) {
        throw Exception('Invalid username or password');
      }
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user.id);
      await prefs.setString('loginType', 'staff');
      return user;
    }

    final portal = await StudentPortalStorage.getByAdmission(username.trim());
    if (portal == null) throw Exception('Invalid username or password');
    if (!portal.isActive) {
      throw Exception('This student portal account has been disabled');
    }
    if (hashPassword(password) != portal.passwordHash) {
      throw Exception('Invalid username or password');
    }

    String fullName = portal.fullName;
    try {
      final students = await StudentStorage.getStudents();
      final match = students.where((s) =>
          s.admissionNo.trim().toLowerCase() ==
          portal.admissionNo.trim().toLowerCase());
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', studentUser.id);
    await prefs.setString('loginType', 'student');
    await prefs.setString('studentAdmissionNo', portal.admissionNo);
    return studentUser;
  }

  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('loginType');
    await prefs.remove('studentAdmissionNo');
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
