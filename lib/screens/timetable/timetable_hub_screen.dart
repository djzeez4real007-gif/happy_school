import 'package:flutter/material.dart';

import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import 'timetable_screen.dart';
import 'timetable_settings_screen.dart';

/// Hub under sidebar "Timetable" — same idea as Register.
class TimetableHubScreen extends StatelessWidget {
  const TimetableHubScreen({super.key});

  bool get canConfigure =>
      Permissions.canConfigureTimetable(AuthService.currentRole);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timetable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'View the class grid or configure periods & breaks',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(
            context,
            icon: Icons.grid_view_rounded,
            title: 'View Timetable',
            subtitle: 'Days × periods grid · copy to classes',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimetableScreen()),
              );
            },
          ),
          if (canConfigure) ...[
            const SizedBox(height: 12),
            _tile(
              context,
              icon: Icons.settings_suggest_rounded,
              title: 'Timetable Settings',
              subtitle: 'Periods, start/end times, short & long break',
              color: const Color(0xFFD97706),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TimetableSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
