import '../database/fs.dart';
import '../models/student.dart';

class StudentStorage {
  static const String boxName = 'students';

  static Future<void> addStudent(Student student) async {
    await Fs.add(boxName, student.toMap());
  }

  static Future<List<Student>> getStudents() async {
    final list = <Student>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(Student.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> deleteStudent(int index) async {
    await Fs.deleteAt(boxName, index);
  }

  static Future<void> updateStudent(int index, Student student) async {
    await Fs.putAt(boxName, index, student.toMap());
  }
}
