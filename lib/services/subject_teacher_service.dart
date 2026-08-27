import '../models/teacher.dart';
import '../models/teacher_subject.dart';
import '../services/auth_service.dart';
import '../services/teacher_storage.dart';
import '../services/teacher_subject_storage.dart';

/// Helpers for subject_teacher role — uses **teacher ↔ subject** assignments
/// (not class-wide subject lists).
class SubjectTeacherService {
  SubjectTeacherService._();

  static bool get isSubjectTeacher =>
      AuthService.currentRole == 'subject_teacher';

  static String? get linkedStaffId {
    final id = AuthService.currentUser?.linkedTeacherId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static Future<Teacher?> linkedTeacher() async {
    final id = linkedStaffId;
    if (id == null) return null;
    try {
      return await TeacherStorage.getTeacher(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<TeacherSubject>> mySubjects() async {
    final id = linkedStaffId;
    if (id == null) return [];
    return TeacherSubjectStorage.forTeacher(id);
  }

  static Future<Set<String>> mySubjectCodes() async {
    final list = await mySubjects();
    return list
        .map((a) => a.subjectCode.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  static Future<Set<String>> mySubjectNames() async {
    final list = await mySubjects();
    return list
        .map((a) => a.subjectName.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
  }

  /// Match timetable cell to this teacher by name and/or subject.
  static Future<bool> timetableEntryIsMine({
    required String entryTeacher,
    required String entrySubject,
    required Set<String> myCodes,
    required Set<String> myNames,
    Teacher? me,
  }) async {
    final et = entryTeacher.trim().toLowerCase();
    final es = entrySubject.trim().toLowerCase();

    if (es.isNotEmpty && (myCodes.contains(es) || myNames.contains(es))) {
      // If subject matches and teacher name empty or matches me → yes
      if (et.isEmpty) return true;
      if (me != null) {
        final full = me.fullName.trim().toLowerCase();
        final sur = me.surname.trim().toLowerCase();
        if (full.isNotEmpty && (et.contains(full) || full.contains(et))) {
          return true;
        }
        if (sur.isNotEmpty && et.contains(sur)) return true;
      }
      // subject is theirs — include period even if name differs slightly
      return true;
    }

    if (me != null && et.isNotEmpty) {
      final full = me.fullName.trim().toLowerCase();
      final sur = me.surname.trim().toLowerCase();
      final first = me.firstName.trim().toLowerCase();
      if (full.isNotEmpty &&
          (et == full || et.contains(full) || full.contains(et))) {
        return true;
      }
      if (sur.isNotEmpty && first.isNotEmpty && et.contains(sur) && et.contains(first)) {
        return true;
      }
    }
    return false;
  }
}
