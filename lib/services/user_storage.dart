import '../database/fs.dart';
import '../models/app_user.dart';

class UserStorage {
  static const String boxName = 'app_users';

  static Future<List<AppUser>> getUsers() async {
    final list = <AppUser>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(AppUser.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<AppUser?> getByUsername(String username) async {
    final target = username.trim().toLowerCase();
    for (final user in await getUsers()) {
      if (user.username.trim().toLowerCase() == target) return user;
    }
    return null;
  }

  static Future<AppUser?> getByUsernameExact(String username) async {
    final target = username.trim();
    for (final user in await getUsers()) {
      if (user.username.trim() == target) return user;
    }
    return null;
  }

  static Future<AppUser?> getById(String id) async {
    for (final user in await getUsers()) {
      if (user.id == id) return user;
    }
    return null;
  }

  static Future<void> addUser(AppUser user) async {
    if (await getByUsername(user.username) != null) {
      throw Exception('Username already exists');
    }
    await Fs.add(boxName, user.toMap());
  }

  static Future<void> updateUser(String id, AppUser user) async {
    final rows = await Fs.getAll(boxName);
    for (final r in rows) {
      final existing = AppUser.fromMap(Map<String, dynamic>.from(r));
      if (existing.id == id) {
        if (existing.username.toLowerCase() != user.username.toLowerCase()) {
          final clash = await getByUsername(user.username);
          if (clash != null && clash.id != id) {
            throw Exception('Username already exists');
          }
        }
        final docId = r['_docId']?.toString();
        if (docId != null) await Fs.set(boxName, docId, user.toMap());
        return;
      }
    }
  }

  static Future<void> deleteUser(String id) async {
    final rows = await Fs.getAll(boxName);
    for (final r in rows) {
      final existing = AppUser.fromMap(Map<String, dynamic>.from(r));
      if (existing.id == id) {
        if (existing.role == 'vendor' ||
            existing.username.toLowerCase() == 'hs.vendor') {
          throw Exception('Cannot delete the vendor account');
        }
        final docId = r['_docId']?.toString();
        if (docId != null) await Fs.delete(boxName, docId);
        return;
      }
    }
  }

  static Future<int> count() async => Fs.count(boxName);
}
