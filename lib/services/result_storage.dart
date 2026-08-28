import 'package:hive_flutter/hive_flutter.dart';

import '../models/result.dart';

class ResultStorage {
  static const String boxName = 'results';

  // ==========================================================
  // SAVE / UPDATE RESULT
  // ==========================================================

  static Future<void> saveResult(Result result) async {
    final box = Hive.box<Map>(boxName);

    final admissionNo = result.admissionNo.trim().toLowerCase();
    final subjectCode = result.subjectCode.trim().toLowerCase();
    final session = result.session.trim().toLowerCase();
    final term = result.term.trim().toLowerCase();

    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);

      if (data == null) continue;

      final item = Result.fromMap(Map<String, dynamic>.from(data));

      final sameStudent = item.admissionNo.trim().toLowerCase() == admissionNo;

      final sameSubject = item.subjectCode.trim().toLowerCase() == subjectCode;

      final sameSession = item.session.trim().toLowerCase() == session;

      final sameTerm = item.term.trim().toLowerCase() == term;

      if (sameStudent && sameSubject && sameSession && sameTerm) {
        await box.putAt(i, result.toMap());
        return;
      }
    }

    await box.add(result.toMap());
  }

  // ==========================================================
  // GET ALL RESULTS
  // ==========================================================

  static Future<List<Result>> getResults() async {
    final box = Hive.box<Map>(boxName);

    return box.values.map((e) {
      return Result.fromMap(Map<String, dynamic>.from(e));
    }).toList();
  }

  // ==========================================================
  // GET CLASS RESULTS
  // ==========================================================

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

  // ==========================================================
  // GET STUDENT RESULTS
  // ==========================================================

  static Future<List<Result>> getStudentResults(String admissionNo) async {
    final results = await getResults();

    final wantedAdmissionNo = admissionNo.trim().toLowerCase();

    return results.where((result) {
      return result.admissionNo.trim().toLowerCase() == wantedAdmissionNo;
    }).toList();
  }

  // ==========================================================
  // GET ONE STUDENT RESULT
  // ==========================================================

  static Future<Result?> getStudentResult({
    required String admissionNo,
    required String subjectCode,
    required String session,
    required String term,
  }) async {
    final box = Hive.box<Map>(boxName);

    final wantedAdmissionNo = admissionNo.trim().toLowerCase();

    final wantedSubjectCode = subjectCode.trim().toLowerCase();

    final wantedSession = session.trim().toLowerCase();

    final wantedTerm = term.trim().toLowerCase();

    for (final item in box.values) {
      final result = Result.fromMap(Map<String, dynamic>.from(item));

      if (result.admissionNo.trim().toLowerCase() == wantedAdmissionNo &&
          result.subjectCode.trim().toLowerCase() == wantedSubjectCode &&
          result.session.trim().toLowerCase() == wantedSession &&
          result.term.trim().toLowerCase() == wantedTerm) {
        return result;
      }
    }

    return null;
  }

  // ==========================================================
  // DELETE RESULT
  // ==========================================================

  static Future<void> deleteResult(int index) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    await box.deleteAt(index);
  }

  // ==========================================================
  // UPDATE RESULT
  // ==========================================================

  static Future<void> updateResult(int index, Result result) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    await box.putAt(index, result.toMap());
  }
}
