import '../database/fs.dart';
import '../models/student_class.dart';

class StudentClassStorage {
  static const String boxName = 'student_classes';

  static StudentClass _fromAny(dynamic raw) {
    if (raw is StudentClass) return raw;
    return StudentClass.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  static Future<void> assignStudent(StudentClass item) async {
    final adm = item.admissionNo.trim().toLowerCase();
    final sess = item.session.trim().toLowerCase();
    final rows = await Fs.getAll(boxName);
    for (final rawAt in rows) {
      final existing = _fromAny(rawAt);
      if (existing.admissionNo.trim().toLowerCase() == adm &&
          existing.session.trim().toLowerCase() == sess) {
        final id = rawAt['_docId']?.toString();
        if (id != null) {
          await Fs.set(boxName, id, item.toMap());
          return;
        }
      }
    }
    await Fs.add(boxName, item.toMap());
  }

  static Future<List<StudentClass>> getStudents() async {
    final list = <StudentClass>[];
    for (final raw in await Fs.getAll(boxName)) {
      try {
        final s = _fromAny(raw);
        if (s.admissionNo.trim().isNotEmpty) list.add(s);
      } catch (_) {}
    }
    return list;
  }

  static Future<List<StudentClass>> getStudentsBySessionTerm({
    required String session,
    required String term,
  }) async {
    final students = await getStudents();
    final s = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    return students.where((e) {
      final okS = e.session.trim().toLowerCase() == s;
      if (t.isEmpty) return okS;
      final et = e.term.trim().toLowerCase();
      return okS && (et.isEmpty || et == t);
    }).toList();
  }

  static Future<List<StudentClass>> getStudentsByClass({
    required String className,
    required String session,
    String term = '',
  }) async {
    final c = className.trim().toLowerCase();
    final s = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    return (await getStudents()).where((e) {
      final okC = e.className.trim().toLowerCase() == c;
      final okS = e.session.trim().toLowerCase() == s;
      if (t.isEmpty) return okC && okS;
      final et = e.term.trim().toLowerCase();
      return okC && okS && (et.isEmpty || et == t);
    }).toList();
  }

  static Future<void> updateStudent(int index, StudentClass item) async {
    await Fs.putAt(boxName, index, item.toMap());
  }

  static Future<void> deleteStudent(int index) async {
    await Fs.deleteAt(boxName, index);
  }

  static Future<StudentClass?> getStudent(String admissionNo) async {
    final adm = admissionNo.trim().toLowerCase();
    final list = await getStudents();
    StudentClass? latest;
    for (final s in list) {
      if (s.admissionNo.trim().toLowerCase() == adm) latest = s;
    }
    return latest;
  }

  static Future<StudentClass?> getStudentForPeriod({
    required String admissionNo,
    required String session,
    String term = '',
  }) async {
    final adm = admissionNo.trim().toLowerCase();
    final s = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    for (final e in await getStudents()) {
      if (e.admissionNo.trim().toLowerCase() != adm) continue;
      if (e.session.trim().toLowerCase() != s) continue;
      if (t.isNotEmpty) {
        final et = e.term.trim().toLowerCase();
        if (et.isNotEmpty && et != t) continue;
      }
      return e;
    }
    return null;
  }

  static Future<List<StudentClass>> getStudentHistory(String admissionNo) async {
    final adm = admissionNo.trim().toLowerCase();
    return (await getStudents())
        .where((e) => e.admissionNo.trim().toLowerCase() == adm)
        .toList();
  }

  static Future<List<StudentClass>> getStudentsBySession(String session) async {
    final s = session.trim().toLowerCase();
    return (await getStudents())
        .where((e) => e.session.trim().toLowerCase() == s)
        .toList();
  }

  static Future<List<StudentClass>> getStudentsByClassAndSession({
    required String className,
    required String session,
  }) async {
    return getStudentsByClass(className: className, session: session);
  }

  static Future<bool> hasAssignment({
    required String admissionNo,
    required String session,
  }) async {
    final a = await getStudentForPeriod(admissionNo: admissionNo, session: session);
    return a != null;
  }

  static Future<int> getTotalAssignedStudents() async => Fs.count(boxName);

  static Future<void> clearAllAssignments() async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
  }
}
