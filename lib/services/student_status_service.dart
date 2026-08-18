import '../models/student.dart';
import '../models/student_class.dart';
import 'student_class_storage.dart';
import 'student_storage.dart';

/// Active vs graduated / left (did not return) helpers.
class StudentStatusService {
  static bool isGraduatedClassName(String className) =>
      className.trim().toLowerCase() == 'graduated';

  static bool isLeftClassName(String className) {
    final c = className.trim().toLowerCase();
    return c == 'left' || c == 'withdrawn' || c == 'left school';
  }

  /// Not in an active class for continuing studies.
  static bool isInactiveClassName(String className) =>
      isGraduatedClassName(className) || isLeftClassName(className);

  static Future<bool> isGraduated(String admissionNo) async {
    final history = await StudentClassStorage.getStudentHistory(admissionNo);
    return history.any((h) => isGraduatedClassName(h.className));
  }

  static Future<bool> hasLeft(String admissionNo) async {
    final history = await StudentClassStorage.getStudentHistory(admissionNo);
    return history.any((h) => isLeftClassName(h.className));
  }

  static Future<StudentClass?> graduationRecord(String admissionNo) async {
    final history = await StudentClassStorage.getStudentHistory(admissionNo);
    final grads = history
        .where((h) => isGraduatedClassName(h.className))
        .toList();
    if (grads.isEmpty) return null;
    grads.sort((a, b) => b.session.compareTo(a.session));
    return grads.first;
  }

  static Future<StudentClass?> leftRecord(String admissionNo) async {
    final history = await StudentClassStorage.getStudentHistory(admissionNo);
    final left = history.where((h) => isLeftClassName(h.className)).toList();
    if (left.isEmpty) return null;
    left.sort((a, b) => b.session.compareTo(a.session));
    return left.first;
  }

  static Future<List<StudentClass>> allGraduatedAssignments() async {
    return _latestByAdmission((h) => isGraduatedClassName(h.className));
  }

  static Future<List<StudentClass>> allLeftAssignments() async {
    return _latestByAdmission((h) => isLeftClassName(h.className));
  }

  static Future<List<StudentClass>> _latestByAdmission(
    bool Function(StudentClass) test,
  ) async {
    final all = await StudentClassStorage.getStudents();
    final byAdm = <String, StudentClass>{};
    for (final a in all) {
      if (!test(a)) continue;
      final key = a.admissionNo.trim().toLowerCase();
      final existing = byAdm[key];
      if (existing == null || a.session.compareTo(existing.session) > 0) {
        byAdm[key] = a;
      }
    }
    final list = byAdm.values.toList();
    list.sort(
      (a, b) => a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()),
    );
    return list;
  }

  static Future<List<Student>> graduatedStudents() async {
    final assigns = await allGraduatedAssignments();
    return _studentsFor(assigns);
  }

  static Future<List<Student>> leftStudents() async {
    final assigns = await allLeftAssignments();
    return _studentsFor(assigns);
  }

  static Future<List<Student>> _studentsFor(List<StudentClass> assigns) async {
    final students = await StudentStorage.getStudents();
    final map = {
      for (final s in students) s.admissionNo.trim().toLowerCase(): s,
    };
    final out = <Student>[];
    for (final a in assigns) {
      final s = map[a.admissionNo.trim().toLowerCase()];
      if (s != null) out.add(s);
    }
    return out;
  }

  static bool isActiveAssignment(StudentClass a) =>
      !isInactiveClassName(a.className);
}
