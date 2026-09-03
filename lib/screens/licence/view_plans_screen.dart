import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/licence_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pricing_package.dart';

class ViewPlansScreen extends StatelessWidget {
  const ViewPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LicenceController.instance,
      builder: (context, _) {
        final packages = LicenceController.instance.packages;
        final contact = LicenceController.instance.licence.contactPhone;
        return Scaffold(
          backgroundColor: AppColors.scaffold(context),
          appBar: AppBar(
            title: const Text('Plans & pricing'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text(
                'School software plans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'View only. Contact the vendor to subscribe or renew.\nPhone / WhatsApp: $contact',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              for (final p in packages) ...[
                _card(context, p),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: contact));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contact copied: $contact')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy vendor contact'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, PricingPackage package) {
    final hi = package.highlighted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hi ? AppColors.primary : AppColors.cardBorder(context),
          width: hi ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hi)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ),
          Text(package.name,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary(context))),
          Text(package.priceLabel,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary)),
          Text(package.period,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12.5)),
          const SizedBox(height: 10),
          for (final f in package.features) ...[
            Row(children: [
              Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(f)),
            ]),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
