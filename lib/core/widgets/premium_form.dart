import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared premium form chrome for registration / settings screens.
class PremiumForm {
  PremiumForm._();

  static Widget page({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    Widget? bottomBar,
    List<Color>? gradient,
  }) {
    final g = gradient ??
        const [Color(0xFF1E40AF), Color(0xFF3B82F6)];

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      bottomNavigationBar: bottomBar,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          header(context, title: title, subtitle: subtitle, icon: icon, gradient: g),
          const SizedBox(height: 16),
          card(context, children: children),
        ],
      ),
    );
  }

  static Widget header(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    List<Color> gradient = const [Color(0xFF1E40AF), Color(0xFF3B82F6)],
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget card(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData icon = Icons.check_rounded,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
