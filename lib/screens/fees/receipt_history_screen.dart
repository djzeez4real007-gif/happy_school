import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student_fee_payment.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import 'receipt_screen.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  List<StudentFeePayment> receipts = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    setState(() => loading = true);
    final data = await StudentFeePaymentStorage.getPayments();
    // Newest first
    data.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    if (!mounted) return;
    setState(() {
      receipts = data;
      loading = false;
    });
  }

  List<StudentFeePayment> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return receipts;
    return receipts.where((r) {
      return r.studentName.toLowerCase().contains(q) ||
          r.admissionNo.toLowerCase().contains(q) ||
          r.receiptNo.toLowerCase().contains(q) ||
          r.className.toLowerCase().contains(q) ||
          r.session.toLowerCase().contains(q) ||
          r.term.toLowerCase().contains(q) ||
          r.paymentMethod.toLowerCase().contains(q);
    }).toList();
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y · $h:$min';
    } catch (_) {
      return raw;
    }
  }

  Future<void> deleteReceipt(StudentFeePayment receipt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete receipt?'),
        content: Text(
          'Remove ${receipt.receiptNo} for ${receipt.studentName}?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Delete by matching receipt number in full list
    final all = await StudentFeePaymentStorage.getPayments();
    final index = all.indexWhere((e) => e.receiptNo == receipt.receiptNo);
    if (index < 0) return;

    await StudentFeePaymentStorage.deletePayment(index);
    await AuditLogStorage.log(
      action: 'receipt_deleted',
      module: 'fees',
      description:
          'Deleted receipt ${receipt.receiptNo} (${receipt.studentName})',
      refId: receipt.receiptNo,
    );
    await loadReceipts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${receipt.receiptNo}'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void openReceipt(StudentFeePayment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          // ===== Premium header =====
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Receipt History',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${list.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText:
                          'Search name, receipt, class, session, term…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
              ],
            ),
          ),

          // ===== Body =====
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isEmpty
                                  ? 'No receipts yet'
                                  : 'No matches for “$query”',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadReceipts,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final r = list[index];
                            final settled = r.balance <= 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.cardBorder(context),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => openReceipt(r),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: settled
                                                  ? const [
                                                      Color(0xFF059669),
                                                      Color(0xFF34D399),
                                                    ]
                                                  : [
                                                      AppColors.primary,
                                                      Color(0xFF60A5FA),
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            r.studentName.isNotEmpty
                                                ? r.studentName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      r.studentName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    onSelected: (value) async {
                                                      if (value == 'view') {
                                                        openReceipt(r);
                                                      } else if (value ==
                                                          'delete') {
                                                        await deleteReceipt(r);
                                                      }
                                                    },
                                                    itemBuilder: (_) => const [
                                                      PopupMenuItem(
                                                        value: 'view',
                                                        child: Text(
                                                            'View receipt'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                r.receiptNo,
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textSecondary(context),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: [
                                                  _chip(
                                                    r.className,
                                                    const Color(0xFFEFF6FF),
                                                    AppColors.primary,
                                                  ),
                                                  if (r.session.isNotEmpty)
                                                    _chip(
                                                      r.session,
                                                      const Color(0xFFF5F3FF),
                                                      const Color(0xFF6D28D9),
                                                    ),
                                                  if (r.term.isNotEmpty)
                                                    _chip(
                                                      r.term,
                                                      const Color(0xFFECFDF5),
                                                      const Color(0xFF047857),
                                                    ),
                                                  _chip(
                                                    r.paymentMethod,
                                                    const Color(0xFFFFF7ED),
                                                    const Color(0xFFC2410C),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₦${r.amountPaid.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 16,
                                                      color: Color(0xFF059669),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    settled
                                                        ? 'Fully paid'
                                                        : 'Bal ₦${r.balance.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: settled
                                                          ? const Color(
                                                              0xFF059669)
                                                          : const Color(
                                                              0xFFDC2626),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    _formatDate(r.paymentDate),
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: AppColors
                                                          .textMuted(context),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
