import '../database/fs.dart';
import '../models/result.dart';

class ResultStorage {
  static const String boxName = 'results';

  static Future<void> saveResult(Result result) async {
    final a = result.admissionNo.trim().toLowerCase();
    final s = result.subjectCode.trim().toLowerCase();
    final se = result.session.trim().toLowerCase();
    final t = result.term.trim().toLowerCase();
    for (final data in await Fs.getAll(boxName)) {
      final item = Result.fromMap(Map<String, dynamic>.from(data));
      if (item.admissionNo.trim().toLowerCase() == a &&
          item.subjectCode.trim().toLowerCase() == s &&
          item.session.trim().toLowerCase() == se &&
          item.term.trim().toLowerCase() == t) {
        final id = data['_docId']?.toString();
        if (id != null) {
          await Fs.set(boxName, id, result.toMap());
          return;
        }
      }
    }
    await Fs.add(boxName, result.toMap());
  }

  static Future<List<Result>> getResults() async {
    final list = <Result>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(Result.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  
  static Future<List<Result>> getClassResults({
    required String className,
    required String session,
    required String term,
  }) async {
    final results = await getResults();
    final wantedClass = className.trim().toLowerCase();
    final wantedSession = session.trim().toLowerCase();
    final wantedTerm = term.trim().toLowerCase();
    return results.where((result) {
      return result.className.trim().toLowerCase() == wantedClass &&
          result.session.trim().toLowerCase() == wantedSession &&
          result.term.trim().toLowerCase() == wantedTerm;
    }).toList();
  }

  static Future<List<Result>> getStudentResults(String admissionNo) async {
    final wanted = admissionNo.trim().toLowerCase();
    return (await getResults())
        .where((r) => r.admissionNo.trim().toLowerCase() == wanted)
        .toList();
  }

  static Future<Result?> getStudentResult({
    required String admissionNo,
    required String subjectCode,
    required String session,
    required String term,
  }) async {
    final a = admissionNo.trim().toLowerCase();
    final s = subjectCode.trim().toLowerCase();
    final se = session.trim().toLowerCase();
    final t = term.trim().toLowerCase();
    for (final result in await getResults()) {
      if (result.admissionNo.trim().toLowerCase() == a &&
          result.subjectCode.trim().toLowerCase() == s &&
          result.session.trim().toLowerCase() == se &&
          result.term.trim().toLowerCase() == t) {
        return result;
      }
    }
    return null;
  }

  static Future<void> deleteResult(int index) async => Fs.deleteAt(boxName, index);
  static Future<void> updateResult(int index, Result result) async =>
      Fs.putAt(boxName, index, result.toMap());
  static Future<int> count() async => Fs.count(boxName);
}
