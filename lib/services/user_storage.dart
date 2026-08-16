import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';

class UserStorage {
  static const String boxName = 'app_users';

  static Box<Map> get _box => Hive.box<Map>(boxName);

  static Future<List<AppUser>> getUsers() async {
    return _box.values
        .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<AppUser?> getByUsername(String username) async {
    final target = username.trim().toLowerCase();
    for (final raw in _box.values) {
      final user = AppUser.fromMap(Map<String, dynamic>.from(raw));
      if (user.username.trim().toLowerCase() == target) {
        return user;
      }
    }
    return null;
  }

  static Future<AppUser?> getByUsernameExact(String username) async {
    final target = username.trim();
    for (final raw in _box.values) {
      final user = AppUser.fromMap(Map<String, dynamic>.from(raw));
      if (user.username.trim() == target) {
        return user;
      }
    }
    return null;
  }

  static Future<AppUser?> getById(String id) async {
    for (final raw in _box.values) {
      final user = AppUser.fromMap(Map<String, dynamic>.from(raw));
      if (user.id == id) return user;
    }
    return null;
  }

  static Future<void> addUser(AppUser user) async {
    // Prevent duplicate username
    final existing = await getByUsername(user.username);
    if (existing != null) {
      throw Exception('Username already exists');
    }
    await _box.add(user.toMap());
    await _box.flush();
  }

  static Future<void> updateUser(String id, AppUser user) async {
    for (int i = 0; i < _box.length; i++) {
      final raw = _box.getAt(i);
      if (raw is! Map) continue;
      final existing = AppUser.fromMap(Map<String, dynamic>.from(raw));
      if (existing.id == id) {
        // If username changed, ensure unique
        if (existing.username.toLowerCase() != user.username.toLowerCase()) {
          final clash = await getByUsername(user.username);
          if (clash != null && clash.id != id) {
            throw Exception('Username already exists');
          }
        }
        await _box.putAt(i, user.toMap());
        await _box.flush();
        return;
      }
    }
  }

  static Future<void> deleteUser(String id) async {
    for (int i = _box.length - 1; i >= 0; i--) {
      final raw = _box.getAt(i);
      if (raw is! Map) continue;
      final existing = AppUser.fromMap(Map<String, dynamic>.from(raw));
      if (existing.id == id) {
        await _box.deleteAt(i);
        await _box.flush();
        return;
      }
    }
  }

  static Future<int> count() async => _box.length;
}
