import 'package:hive/hive.dart';

import '../models/audit_log.dart';
import 'auth_service.dart';

class AuditLogStorage {
  static const String boxName = 'audit_logs';

  static const _ignoredActions = {
    'login',
    'logout',
    'user_login',
    'user_logout',
  };

  static Future<Box> _box() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return Hive.openBox(boxName);
  }

  static Future<void> log({
    required String action,
    required String module,
    required String description,
    String? refId,
    String? session,
    String? term,
  }) async {
    final a = action.trim().toLowerCase();
    if (_ignoredActions.contains(a)) return;

    final user = AuthService.currentUser;
    final entry = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      module: module,
      description: description,
      userId: user?.id ?? '',
      userName: user?.fullName ?? 'System',
      userRole: user?.role ?? '',
      timestamp: DateTime.now().toIso8601String(),
      refId: refId,
      session: session,
      term: term,
    );
    final box = await _box();
    await box.add(entry.toMap());
  }

  static Future<List<AuditLog>> getAll() async {
    final box = await _box();
    final list = box.values
        .map((e) => AuditLog.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((e) => !_ignoredActions.contains(e.action.trim().toLowerCase()))
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}
