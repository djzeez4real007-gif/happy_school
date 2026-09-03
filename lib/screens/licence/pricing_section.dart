import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/licence_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pricing_package.dart';

/// Pricing cards for pre-login / welcome website.
class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  void _contact(BuildContext context) {
    final phone = LicenceController.instance.licence.contactWhatsapp;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contact WhatsApp/Phone: $phone (copied). Pay by transfer, then we activate your school.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packages = LicenceController.instance.packages;
    final contact = LicenceController.instance.licence.contactPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Plans & pricing',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'One-time, term, or yearly — choose what fits your school',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            final cards = packages
                .map((p) => _PackageCard(
                      package: p,
                      onContact: () => _contact(context),
                    ))
                .toList();
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (final w in cards) ...[
                  w,
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Pay by bank transfer or online. We activate your school after payment.\nContact: $contact',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PricingPackage package;
  final VoidCallback onContact;

  const _PackageCard({required this.package, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final hi = package.highlighted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hi ? AppColors.primary : AppColors.cardBorder(context),
          width: hi ? 2 : 1,
        ),
        boxShadow: hi
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hi)
            Container(
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (hi) const SizedBox(height: 8),
          Text(
            package.name,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            package.priceLabel,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Text(
            package.period,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final f in package.features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContact,
              style: FilledButton.styleFrom(
                backgroundColor:
                    hi ? AppColors.primary : const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Get this plan'),
            ),
          ),
        ],
      ),
    );
  }
}
