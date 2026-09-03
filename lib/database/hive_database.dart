import 'package:hive_flutter/hive_flutter.dart';

import '../services/subject_storage.dart';
import '../services/auth_service.dart';

class HiveDatabase {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Students
    await Hive.openBox<Map>('students');

    // Teachers
    await Hive.openBox<Map>('teachers');

    // Subjects
    await Hive.openBox<Map>('subjects');

    // Classes
    await Hive.openBox<Map>('classes');

    // Student Class Assignment
    await Hive.openBox<Map>('student_classes');

    // Student Subjects
    await Hive.openBox<Map>('student_subjects');

    // Class Subjects
    await Hive.openBox<Map>('class_subjects');

    // Results
    await Hive.openBox<Map>('results');

    // Fees
    await Hive.openBox<Map>('school_fees');

    // Payments
    await Hive.openBox<Map>('student_fee_payments');

    // Users (roles & login)
    await Hive.openBox<Map>('app_users');

    // Auth session
    await Hive.openBox('auth_session');

    // Audit log
    await Hive.openBox('audit_logs');

    await Hive.openBox('non_teaching_staff');

    await Hive.openBox('welcome_media');
    await Hive.openBox('welcome_images');
    await Hive.openBox('school_profile');
    await Hive.openBox('school_licence');
    await Hive.openBox('pricing_packages');
    await Hive.openBox('teacher_subjects');

    // Timetable
    await Hive.openBox<Map>('timetables');
    await Hive.openBox('timetable_settings');
    await Hive.openBox('student_portal');
    if (!Hive.isBoxOpen('announcements')) {
      await Hive.openBox('announcements');
    }

    await SubjectStorage.seedDefaultSubjects();

    // Create default admin if no users exist
    await AuthService.seedDefaultAdmin();

    // Restore session if user was logged in
    await AuthService.initSession();
  }
}
