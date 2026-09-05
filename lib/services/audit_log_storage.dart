import '../database/fs.dart';
import '../models/audit_log.dart';
import 'auth_service.dart';

class AuditLogStorage {
  static const String boxName = 'audit_logs';
  static const _ignoredActions = {
    'login', 'logout', 'user_login', 'user_logout',
  };

  static Future<void> log({
    required String action,
    required String module,
    required String description,
    String? refId,
    String? session,
    String? term,
  }) async {
    if (_ignoredActions.contains(action.trim().toLowerCase())) return;
    final user = AuthService.currentUser;
    await Fs.add(boxName, AuditLog(
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
    ).toMap());
  }

  static Future<List<AuditLog>> getAll() async {
    final list = <AuditLog>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        final log = AuditLog.fromMap(Map<String, dynamic>.from(e));
        if (!_ignoredActions.contains(log.action.trim().toLowerCase())) {
          list.add(log);
        }
      } catch (_) {}
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}
