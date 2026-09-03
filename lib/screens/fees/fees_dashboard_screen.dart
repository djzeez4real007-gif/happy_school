import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../models/school_class.dart';
import '../../services/class_storage.dart';
import '../../services/fees_dashboard_service.dart';
import 'school_fee_screen.dart';
import 'student_fee_payment_screen.dart';
import 'receipt_history_screen.dart';
import 'debtors_list_screen.dart';
import 'student_payment_history_screen.dart';
import 'receipt_archive_screen.dart';
import 'fee_payment_status_screen.dart';
import 'financial_reports_screen.dart';

class FeesDashboardScreen extends StatefulWidget {
  const FeesDashboardScreen({super.key});

  @override
  State<FeesDashboardScreen> createState() => _FeesDashboardScreenState();
}

class _FeesDashboardScreenState extends State<FeesDashboardScreen> {
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  String selectedClass = 'All';
  final sessions = Sessions.list();
  final terms = Sessions.terms;
  List<SchoolClass> classes = [];

  bool loading = true;
  double collected = 0;
  double cashCollected = 0;
  double posCollected = 0;
  double transferCollected = 0;
  double outstanding = 0;
  int debtors = 0;
  int studentsPaid = 0;
  double collectionPct = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    classes = await ClassStorage.getClasses();
    classes.sort(
      (a, b) => a.fullClassName.toLowerCase().compareTo(
        b.fullClassName.toLowerCase(),
      ),
    );
    await loadStats();
  }

  Future<void> loadStats() async {
    setState(() => loading = true);
    try {
      final classFilter = selectedClass;
      collected = await FeesDashboardService.totalFeesCollected(
        session: selectedSession,
        term: selectedTerm,
        classFilter: classFilter,
      );
      final byMethod = await FeesDashboardService.collectedByMethod(
        session: selectedSession,
        term: selectedTerm,
        classFilter: classFilter,
      );
      cashCollected = byMethod['cash'] ?? 0;
      posCollected = byMethod['pos'] ?? 0;
      transferCollected = byMethod['transfer'] ?? 0;
      outstanding = await FeesDashboardService.totalOutstanding(
        session: selectedSession,
        term: selectedTerm,
        classFilter: classFilter,
      );
      debtors = await FeesDashboardService.totalDebtors(
        session: selectedSession,
        term: selectedTerm,
        classFilter: classFilter,
      );
      studentsPaid = await FeesDashboardService.totalStudentsPaid(
        session: selectedSession,
        term: selectedTerm,
        classFilter: classFilter,
      );
      collectionPct = await FeesDashboardService.collectionPercentage(
        session: selectedSession,
        term: selectedTerm,
        classFilter: classFilter,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() => loading = false);
  }

  String money(double v) {
    final s = v.toStringAsFixed(0);
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₦$withCommas';
  }

  @override
  Widget build(BuildContext context) {
    final classNames = ['All', ...classes.map((c) => c.fullClassName)];

    final items = [
      _FeeItem(
        icon: Icons.settings_rounded,
        title: 'Fee Settings',
        subtitle: 'Set school fee amounts',
        color: AppColors.primary,
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
        icon: Icons.table_chart_rounded,
        title: 'Payment Status',
        subtitle: 'Paid & unpaid students table',
        color: const Color(0xFF0F766E),
        page: const FeePaymentStatusScreen(),
      ),
      _FeeItem(
        icon: Icons.print_rounded,
        title: 'Print Receipts',
        subtitle: 'Archive and reprint receipts',
        color: const Color(0xFF7C3AED),
        page: const ReceiptArchiveScreen(),
      ),
      _FeeItem(
        icon: Icons.assessment_rounded,
        title: 'Financial Reports',
        subtitle: 'Expected · collected · outstanding',
        color: const Color(0xFF4F46E5),
        page: const FinancialReportsScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: RefreshIndicator(
        onRefresh: loadStats,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF065F46),
                      Color(0xFF059669),
                      Color(0xFF34D399),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Fees Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: loadStats,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Session · Term · Class filters for live totals',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Filters
                      Row(
                        children: [
                          Expanded(
                            child: _filterChip(
                              value: sessions.contains(selectedSession)
                                  ? selectedSession
                                  : sessions.first,
                              items: sessions,
                              onChanged: (v) async {
                                if (v == null) return;
                                selectedSession = v;
                                await loadStats();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _filterChip(
                              value: selectedTerm,
                              items: terms,
                              onChanged: (v) async {
                                if (v == null) return;
                                selectedTerm = v;
                                await loadStats();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _filterChip(
                        value: classNames.contains(selectedClass)
                            ? selectedClass
                            : 'All',
                        items: classNames,
                        onChanged: (v) async {
                          if (v == null) return;
                          selectedClass = v;
                          await loadStats();
                        },
                      ),
                      const SizedBox(height: 16),
                      // Stat cards
                      if (loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _statBoxWithBreakdown(
                                'Collected',
                                money(collected),
                                Icons.payments_rounded,
                                cash: money(cashCollected),
                                pos: money(posCollected),
                                transfer: money(transferCollected),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statBox(
                                'Outstanding',
                                money(outstanding),
                                Icons.warning_amber_rounded,
                              ),
                            ),
                          ],
                        ),
                      if (!loading) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _statBox(
                                'Debtors',
                                '$debtors',
                                Icons.people_alt_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statBox(
                                'Collection',
                                '${collectionPct.toStringAsFixed(0)}%',
                                Icons.pie_chart_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  return _FeeCard(item: item);
                }, childCount: items.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF065F46),
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statBoxWithBreakdown(
    String title,
    String value,
    IconData icon, {
    required String cash,
    required String pos,
    required String transfer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cash $cash  ·  POS $pos  ·  Transfer $transfer',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
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
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => item.page));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
