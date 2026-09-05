import 'package:flutter/material.dart';

/// Shows a back arrow only when the route can pop (not shell tabs).
class AppBack {
  static Widget? leading(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      return const BackButton();
    }
    return null;
  }
}
