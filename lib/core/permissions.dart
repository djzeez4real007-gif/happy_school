/// Central place for what each role can access.
class Permissions {
  static const String dashboard = 'dashboard';
  static const String students = 'students';
  static const String teachers = 'teachers';
  static const String classes = 'classes';
  static const String subjects = 'subjects';
  static const String assignSubjects = 'assign_subjects';
  static const String resultEntry = 'result_entry';
  static const String broadsheet = 'broadsheet';
  static const String reportCards = 'report_cards';
  static const String promotion = 'promotion';
  static const String attendance = 'attendance';
  static const String timetable = 'timetable';
  static const String fees = 'fees';
  static const String announcements = 'announcements';
  static const String users = 'users';
  static const String auditLog = 'audit_log';
  static const String parentPortal = 'parent_portal';
  static const String idCards = 'id_cards';

  static bool canAccess(String role, String feature) {
    switch (role) {
      case 'admin':
        return true;

      case 'principal':
        // Principal sees everything except cannot delete admin (enforced in UI)
        return feature != idCards || true;

      case 'class_teacher':
        // Only: enter results, broadsheet, attendance, timetable (+ dashboard)
        return {
          dashboard,
          resultEntry,
          broadsheet,
          attendance,
        }.contains(feature);

      case 'subject_teacher':
        // Only: enter result, broadsheet, timetable (+ dashboard)
        return {
          dashboard,
          resultEntry,
          broadsheet,
          timetable,
        }.contains(feature);

      case 'accountant':
        // Only: manage fees, financial reports (under fees menu)
        return {
          dashboard,
          fees,
        }.contains(feature);

      case 'parent':
        // Only own children's data via parent portal
        return {
          dashboard,
          parentPortal,
          announcements,
        }.contains(feature);

      default:
        return feature == dashboard;
    }
  }

  static bool canManageUsers(String role) =>
      role == 'admin' || role == 'principal';

  static bool canDeleteUser(String actorRole, String targetRole) {
    // Principal cannot delete administrator
    if (actorRole == 'principal' && targetRole == 'admin') return false;
    // Nobody deletes the last admin via this helper (extra safety in UI)
    if (targetRole == 'admin' && actorRole != 'admin') return false;
    return canManageUsers(actorRole);
  }

  static bool canEditResults(String role) =>
      role == 'admin' ||
      role == 'principal' ||
      role == 'class_teacher' ||
      role == 'subject_teacher';

  static bool canPromote(String role) =>
      role == 'admin' || role == 'principal';

  static bool canManageFees(String role) =>
      role == 'admin' || role == 'principal' || role == 'accountant';
}
