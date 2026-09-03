import 'package:flutter/material.dart';

import '../core/licence_controller.dart';
import '../core/theme/app_colors.dart';

class LicenceBanner extends StatelessWidget {
  const LicenceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LicenceController.instance,
      builder: (context, _) {
        final l = LicenceController.instance.licence;
        if (!l.isExpired && !l.isExpiringSoon) {
          return const SizedBox.shrink();
        }
        final expired = l.isExpired;
        final bg = expired ? const Color(0xFFDC2626) : const Color(0xFFD97706);
        final msg = expired
            ? 'Subscription expired — renew to keep full access. WhatsApp ${l.contactWhatsapp}'
            : 'Licence expires in ${l.daysRemaining} day(s). Renew early to avoid interruption.';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
