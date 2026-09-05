import 'package:flutter/material.dart';

import 'app.dart';
import 'core/licence_controller.dart';
import 'core/school_profile_controller.dart';
import 'core/theme/theme_controller.dart';
import 'database/cloud_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CloudDatabase.init();
  await ThemeController.instance.load();
  await SchoolProfileController.instance.load();
  await LicenceController.instance.load();

  runApp(const HappySchoolApp());
}
