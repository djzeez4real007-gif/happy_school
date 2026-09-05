import 'school_branding.dart';
import 'school_profile_controller.dart';
import 'web_favicon_stub.dart'
    if (dart.library.html) 'web_favicon_web.dart' as impl;

/// Browser tab title + favicon from school logo (web).
class WebFavicon {
  static void apply() {
    final name = SchoolProfileController.instance.name;
    final bytes = SchoolBranding.logoBytes;
    impl.applyWebFavicon(
      title: name.isEmpty ? 'School ERP' : '$name ERP',
      logoBytes: bytes,
    );
  }
}
