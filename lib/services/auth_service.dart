import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';
import 'user_storage.dart';
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

    final user = await UserStorage.getById(userId);
    if (user != null && user.isActive) {
      _currentUser = user;
    } else {
      await box.clear();
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

    if (user == null) {
      throw Exception('Invalid username or password');
    }

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

    try {
      await AuditLogStorage.log(
        action: 'login',
        module: 'auth',
        description: '${user.fullName} logged in as ${user.role}',
        refId: user.username,
      );
    } catch (_) {}

    return user;
  }

  static Future<void> logout() async {
    try {
      final u = _currentUser;
      if (u != null) {
        await AuditLogStorage.log(
          action: 'logout',
          module: 'auth',
          description: '${u.fullName} logged out',
          refId: u.username,
        );
      }
    } catch (_) {}

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
