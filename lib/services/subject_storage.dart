import 'package:hive_flutter/hive_flutter.dart';

import '../models/subject.dart';

class SubjectStorage {
  static const String boxName = 'subjects';

  // ==========================================================
  // ADD / UPDATE SUBJECT
  // ==========================================================

  static Future<void> addSubject(Subject subject) async {
    final box = Hive.box<Map>(boxName);

    final subjectCode = subject.subjectCode.trim().toLowerCase();

    final studentClass = subject.studentClass.trim().toLowerCase();

    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);

      if (raw == null) continue;

      final item = Subject.fromMap(Map<String, dynamic>.from(raw));

      if (item.subjectCode.trim().toLowerCase() == subjectCode &&
          item.studentClass.trim().toLowerCase() == studentClass) {
        await box.putAt(i, subject.toMap());
        return;
      }
    }

    await box.add(subject.toMap());
  }

  // ==========================================================
  // GET ALL SUBJECTS
  // ==========================================================

  static Future<List<Subject>> getSubjects() async {
    final box = Hive.box<Map>(boxName);

    return box.values.map((e) {
      return Subject.fromMap(Map<String, dynamic>.from(e));
    }).toList();
  }

  // ==========================================================
  // REMOVE DUPLICATES
  // ==========================================================

  static Future<void> removeDuplicateSubjects() async {
    final box = Hive.box<Map>(boxName);

    final Set<String> seen = {};
    final List<int> indexesToDelete = [];

    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);

      if (raw == null) continue;

      final subject = Subject.fromMap(Map<String, dynamic>.from(raw));

      final code = subject.subjectCode.trim().toLowerCase();

      final className = subject.studentClass.trim().toLowerCase();

      final uniqueKey = '$code|$className';

      if (seen.contains(uniqueKey)) {
        indexesToDelete.add(i);
      } else {
        seen.add(uniqueKey);
      }
    }

    for (final index in indexesToDelete.reversed) {
      if (index >= 0 && index < box.length) {
        await box.deleteAt(index);
      }
    }
  }

  // ==========================================================
  // TOTAL SUBJECTS
  // ==========================================================

  static Future<int> getTotalSubjects() async {
    final box = Hive.box<Map>(boxName);
    return box.length;
  }

  // ==========================================================
  // GET SUBJECTS BY CLASS
  // ==========================================================

  static Future<List<Subject>> getSubjectsByClass(String className) async {
    final subjects = await getSubjects();

    final wantedClass = className.trim().toLowerCase();

    return subjects.where((subject) {
      return subject.studentClass.trim().toLowerCase() == wantedClass;
    }).toList();
  }

  // ==========================================================
  // GET ONE SUBJECT
  // ==========================================================

  static Future<Subject?> getSubject(
    String subjectCode,
    String className,
  ) async {
    final box = Hive.box<Map>(boxName);

    final wantedCode = subjectCode.trim().toLowerCase();

    final wantedClass = className.trim().toLowerCase();

    for (final item in box.values) {
      final subject = Subject.fromMap(Map<String, dynamic>.from(item));

      if (subject.subjectCode.trim().toLowerCase() == wantedCode &&
          subject.studentClass.trim().toLowerCase() == wantedClass) {
        return subject;
      }
    }

    return null;
  }

  // ==========================================================
  // DELETE SUBJECT
  // ==========================================================


  /// Delete every stored row with this subject code (all class variants).
  static Future<void> deleteSubjectByCode(String subjectCode) async {
    final box = Hive.box<Map>(boxName);
    final code = subjectCode.trim().toLowerCase();
    final toDelete = <int>[];
    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw == null) continue;
      try {
        final item = Subject.fromMap(Map<String, dynamic>.from(raw));
        if (item.subjectCode.trim().toLowerCase() == code) {
          toDelete.add(i);
        }
      } catch (_) {}
    }
    for (final i in toDelete.reversed) {
      await box.deleteAt(i);
    }
  }

  /// Update all rows with matching subject code (name/code fields).
  static Future<void> updateSubjectByCode(String oldCode, Subject subject) async {
    final box = Hive.box<Map>(boxName);
    final code = oldCode.trim().toLowerCase();
    for (int i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw == null) continue;
      try {
        final item = Subject.fromMap(Map<String, dynamic>.from(raw));
        if (item.subjectCode.trim().toLowerCase() == code) {
          final updated = Subject(
            subjectName: subject.subjectName,
            subjectCode: subject.subjectCode,
            studentClass: item.studentClass.isNotEmpty
                ? item.studentClass
                : subject.studentClass,
          );
          await box.putAt(i, updated.toMap());
        }
      } catch (_) {}
    }
  }

  static Future<void> deleteSubject(int index) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    await box.deleteAt(index);
  }

  // ==========================================================
  // UPDATE SUBJECT
  // ==========================================================

  static Future<void> updateSubject(int index, Subject subject) async {
    final box = Hive.box<Map>(boxName);

    if (index < 0 || index >= box.length) {
      return;
    }

    final subjectCode = subject.subjectCode.trim().toLowerCase();

    final studentClass = subject.studentClass.trim().toLowerCase();

    for (int i = 0; i < box.length; i++) {
      if (i == index) continue;

      final raw = box.getAt(i);

      if (raw == null) continue;

      final existing = Subject.fromMap(Map<String, dynamic>.from(raw));

      if (existing.subjectCode.trim().toLowerCase() == subjectCode &&
          existing.studentClass.trim().toLowerCase() == studentClass) {
        return;
      }
    }

    await box.putAt(index, subject.toMap());
  }

  // ==========================================================
  // DEFAULT SUBJECTS
  // ==========================================================

  static Future<void> seedDefaultSubjects() async {
    final box = Hive.box<Map>(boxName);

    if (box.isNotEmpty) {
      await removeDuplicateSubjects();
      return;
    }

    final List<Subject> subjects = [
      // ================= JSS1 =================
      Subject(
        subjectName: 'English Language',
        subjectCode: 'ENG',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Mathematics',
        subjectCode: 'MTH',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Basic Science',
        subjectCode: 'BST',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Basic Technology',
        subjectCode: 'BTE',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Social Studies',
        subjectCode: 'SOS',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Business Studies',
        subjectCode: 'BUS',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Computer Studies',
        subjectCode: 'COM',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Agricultural Science',
        subjectCode: 'AGR',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Civic Education',
        subjectCode: 'CVE',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'National Values',
        subjectCode: 'NAV',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Home Economics',
        subjectCode: 'HME',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Cultural & Creative Arts',
        subjectCode: 'CCA',
        studentClass: 'JSS1',
      ),
      Subject(
        subjectName: 'Physical & Health Education',
        subjectCode: 'PHE',
        studentClass: 'JSS1',
      ),
      Subject(subjectName: 'Yoruba', subjectCode: 'YOR', studentClass: 'JSS1'),
      Subject(subjectName: 'French', subjectCode: 'FRE', studentClass: 'JSS1'),
      Subject(
        subjectName: 'Islamic Studies',
        subjectCode: 'IRS',
        studentClass: 'JSS1',
      ),

      // ================= SS1 =================
      Subject(
        subjectName: 'English Language',
        subjectCode: 'ENG',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Mathematics',
        subjectCode: 'MTH',
        studentClass: 'SS1',
      ),
      Subject(subjectName: 'Biology', subjectCode: 'BIO', studentClass: 'SS1'),
      Subject(
        subjectName: 'Chemistry',
        subjectCode: 'CHE',
        studentClass: 'SS1',
      ),
      Subject(subjectName: 'Physics', subjectCode: 'PHY', studentClass: 'SS1'),
      Subject(
        subjectName: 'Economics',
        subjectCode: 'ECO',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Government',
        subjectCode: 'GOV',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Literature in English',
        subjectCode: 'LIT',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Geography',
        subjectCode: 'GEO',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Financial Accounting',
        subjectCode: 'ACC',
        studentClass: 'SS1',
      ),
      Subject(subjectName: 'Commerce', subjectCode: 'COM', studentClass: 'SS1'),
      Subject(
        subjectName: 'Agricultural Science',
        subjectCode: 'AGR',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Computer Studies',
        subjectCode: 'CPT',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Data Processing',
        subjectCode: 'DTP',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Civic Education',
        subjectCode: 'CVE',
        studentClass: 'SS1',
      ),
      Subject(
        subjectName: 'Islamic Studies',
        subjectCode: 'IRS',
        studentClass: 'SS1',
      ),
    ];

    for (final subject in subjects) {
      await addSubject(subject);
    }

    await removeDuplicateSubjects();
  }
}
