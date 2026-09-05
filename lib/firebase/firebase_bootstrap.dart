import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  static bool ready = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      ready = true;
      debugPrint('Firebase: ENABLED (connected to happyschool-56835)');
    } catch (e, st) {
      ready = false;
      debugPrint('Firebase init failed: $e');
      debugPrint('$st');
    }
  }
}
