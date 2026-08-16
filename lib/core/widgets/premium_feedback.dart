import 'package:flutter/material.dart';

/// Premium animated confirm dialogs and success toasts
/// used across the app (logout, save, create, delete, etc.).
class PremiumFeedback {
  PremiumFeedback._();

  // ----------------------------------------------------------
  // CONFIRM DIALOG (logout, delete, etc.)
  // ----------------------------------------------------------

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    Color accent = const Color(0xFF1D4ED8),
    bool isDestructive = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim, secondary) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, secondary, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDestructive
                                  ? const Color(0xFFDC2626)
                                  : accent)
                              .withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          isDestructive
                              ? Icons.logout_rounded
                              : icon,
                          size: 30,
                          color: isDestructive
                              ? const Color(0xFFDC2626)
                              : accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(ctx).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Theme.of(ctx).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                cancelText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDestructive
                                    ? const Color(0xFFDC2626)
                                    : accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return result == true;
  }

  // ----------------------------------------------------------
  // SUCCESS TOAST (saved, created, updated…)
  // ----------------------------------------------------------

  static void success(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.check_rounded,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    _showBanner(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: const [Color(0xFF16A34A), Color(0xFF22C55E)],
      duration: duration,
    );
  }

  static void info(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.info_rounded,
  }) {
    _showBanner(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    _showBanner(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.error_outline_rounded,
      gradient: const [Color(0xFFB91C1C), Color(0xFFEF4444)],
    );
  }

  static void _showBanner(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Color> gradient,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
