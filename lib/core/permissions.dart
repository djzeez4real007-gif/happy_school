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
  static const String classAverages = 'class_averages';
  static const String alumni = 'alumni';

  static bool canAccess(String role, String feature) {
    switch (role) {
      case 'admin':
        return true;

      case 'principal':
        return true;

      case 'class_teacher':
        // Results, broadsheet, attendance, view timetable, term averages,
        // view announcements only
        return {
          dashboard,
          resultEntry,
          broadsheet,
          attendance,
          timetable,
          classAverages,
          announcements,
        }.contains(feature);

      case 'subject_teacher':
        // View announcements only (no create/edit/delete)
        return {
          dashboard,
          resultEntry,
          broadsheet,
          timetable,
          classAverages,
          announcements,
        }.contains(feature);

      case 'accountant':
        return {
          dashboard,
          fees,
        }.contains(feature);

      case 'parent':
        // Parent portal + view announcements only
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
    if (actorRole == 'principal' && targetRole == 'admin') return false;
    if (targetRole == 'admin' && actorRole != 'admin') return false;
    return canManageUsers(actorRole);
  }

  /// Only admin & principal can add/edit/delete timetable entries.
  /// Subject teacher, class teacher, parent, accountant: view only (or no access).
  static bool canConfigureTimetable(String role) {
    return role == 'admin' || role == 'principal';
  }

  static bool canManageAnnouncements(String role) {
    // Class teacher, subject teacher, parent: view only
    return role == 'admin' || role == 'principal';
  }
}
