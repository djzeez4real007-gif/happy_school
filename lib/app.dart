import 'package:flutter/material.dart';

import 'core/school_profile_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/splash/splash_screen.dart';

class HappySchoolApp extends StatelessWidget {
  const HappySchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        SchoolProfileController.instance,
      ]),
      builder: (context, _) {
        final primary = SchoolProfileController.instance.primary;
        final accent = SchoolProfileController.instance.accent;
        final name = SchoolProfileController.instance.name;
        return MaterialApp(
          title: '$name ERP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(primary: primary, accent: accent),
          darkTheme: AppTheme.darkTheme(primary: primary, accent: accent),
          themeMode: ThemeController.instance.mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
