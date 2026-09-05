# Firebase migration (planned)

Current production data path: **Hive (local)**.

Firebase is **scaffolded only** (`lib/firebase/`) so the app does not break.

## When you are ready for online DB

1. Install Firebase CLI and FlutterFire CLI  
2. `flutter pub add firebase_core cloud_firestore`  
3. `flutterfire configure`  
4. Set `FirebaseConfig.enabled = true` in `lib/firebase/firebase_config.dart`  
5. Uncomment init in `firebase_bootstrap.dart`  
6. Migrate storage classes one module at a time (students → classes → results…)  

Do **not** switch all modules at once without testing — risk of data loss.
