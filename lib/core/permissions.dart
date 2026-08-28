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
  static const String transcript = 'transcript';
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
  static const String media = 'media';
  static const String myTeaching = 'my_teaching';
  static const String assignTeacherSubjects = 'assign_teacher_subjects';
  static const String studentPortal = 'student_portal';
  static const String studentPortalAdmin = 'student_portal_admin';

  static bool canAccess(String role, String feature) {
    switch (role) {
      case 'admin':
      case 'principal':
        // Full access except role-specific portals
        if (feature == studentPortal ||
            feature == parentPortal ||
            feature == myTeaching) {
          return false;
        }
        return true;

      case 'class_teacher':
        // Results, broadsheet, attendance, view timetable, term averages,
        // view announcements only
        return {
          dashboard,
          resultEntry,
          broadsheet,
          reportCards,
          transcript,
          attendance,
          timetable,
          classAverages,
          announcements,
        }.contains(feature);

      case 'subject_teacher':
        // Sidebar: My Teaching + Announcements only.
        // Results / timetable open from inside My Teaching.
        return {
          myTeaching,
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

      case 'student':
        return {
          studentPortal,
          announcements,
        }.contains(feature);

      default:
        return feature == dashboard;
    }
  }

  static bool canManageUsers(String role) =>
      role == 'admin' || role == 'principal';

  /// Only Administrator can delete users (not Principal).
  static bool canDeleteUser(String actorRole, [String? targetRole]) {
    return actorRole == 'admin';
  }

  /// Principal may view fees but not set amounts or record payments.
  static bool canEditFees(String role) {
    return role == 'admin' || role == 'accountant';
  }

  static bool canViewFees(String role) {
    return role == 'admin' ||
        role == 'principal' ||
        role == 'accountant';
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
