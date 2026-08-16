import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import 'school_fee_screen.dart';
import 'student_fee_payment_screen.dart';
import 'receipt_history_screen.dart';
import 'debtors_list_screen.dart';
import 'student_payment_history_screen.dart';
import 'receipt_archive_screen.dart';
import 'fees_statistics_screen.dart';

class FeesDashboardScreen extends StatelessWidget {
  const FeesDashboardScreen({super.key});

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    final items = [
      _FeeItem(
        icon: Icons.settings_rounded,
        title: 'Fee Settings',
        subtitle: 'Set school fee amounts',
        color: const Color(0xFF2563EB),
        page: const SchoolFeeScreen(),
      ),
      _FeeItem(
        icon: Icons.payments_rounded,
        title: 'Receive Payment',
        subtitle: 'Record student fee payments',
        color: const Color(0xFF059669),
        page: const StudentFeePaymentScreen(),
      ),
      _FeeItem(
        icon: Icons.receipt_long_rounded,
        title: 'Receipt History',
        subtitle: 'View past payment receipts',
        color: const Color(0xFFD97706),
        page: const ReceiptHistoryScreen(),
      ),
      _FeeItem(
        icon: Icons.person_search_rounded,
        title: 'Student Payments',
        subtitle: 'All receipts for one student',
        color: const Color(0xFF0284C7),
        page: const StudentPaymentHistoryScreen(),
      ),
      _FeeItem(
        icon: Icons.people_alt_rounded,
        title: 'Debtors List',
        subtitle: 'Students with outstanding fees',
        color: const Color(0xFFDC2626),
        page: const DebtorsListScreen(),
      ),
      _FeeItem(
        icon: Icons.print_rounded,
        title: 'Print Receipts',
        subtitle: 'Archive and reprint receipts',
        color: const Color(0xFF7C3AED),
        page: const ReceiptArchiveScreen(),
      ),
      _FeeItem(
        icon: Icons.bar_chart_rounded,
        title: 'Fees Statistics',
        subtitle: 'Collections overview',
        color: const Color(0xFF0D9488),
        page: const FeesStatisticsScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fees',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Payments · Receipts · Debtors · Reports',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return _FeeCard(item: item);
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;

  const _FeeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
}

class _FeeCard extends StatelessWidget {
  final _FeeItem item;

  const _FeeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
