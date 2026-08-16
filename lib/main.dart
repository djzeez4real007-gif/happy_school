import 'package:flutter/material.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'database/hive_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveDatabase.init();
  await ThemeController.instance.load();

  runApp(const HappySchoolApp());
}
