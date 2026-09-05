import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../services/auth_service.dart';
import '../services/subject_storage.dart';

class CloudDatabase {
  static bool ready = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      ready = true;
      debugPrint('CloudDatabase: Firebase READY (Firestore online)');
    } catch (e, st) {
      ready = false;
      debugPrint('CloudDatabase init error: $e');
      debugPrint('$st');
      rethrow;
    }

    await SubjectStorage.seedDefaultSubjects();
    await AuthService.seedDefaultAdmin();
    await AuthService.initSession();
  }
}
