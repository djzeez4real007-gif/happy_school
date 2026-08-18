import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/school_fee.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../models/student_fee_payment.dart';
import '../../services/school_fee_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_storage.dart';
import 'receipt_screen.dart';

class StudentFeePaymentScreen extends StatefulWidget {
  const StudentFeePaymentScreen({super.key});

  @override
  State<StudentFeePaymentScreen> createState() =>
      _StudentFeePaymentScreenState();
}

class _StudentFeePaymentScreenState extends State<StudentFeePaymentScreen> {
  List<Student> students = [];
  Student? selectedStudent;
  StudentClass? studentClass;
  SchoolFee? schoolFee;

  final amountController = TextEditingController();
  final studentSearchController = TextEditingController();
  String studentSearch = '';
  String receiptNo = '';
  String paymentMethod = 'Cash';
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  final List<String> sessions = Sessions.list();
  final List<String> terms = Sessions.terms;
  double totalFee = 0;
  double totalPaid = 0;
  double balance = 0;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadStudents();
    generateReceipt();
  }

  Future<void> loadStudents() async {
    students = await StudentStorage.getStudents();
    if (mounted) setState(() {});
  }

  Future<void> generateReceipt() async {
    receiptNo = await StudentFeePaymentStorage.generateReceiptNumber();
    if (mounted) setState(() {});
  }

  Future<void> loadStudentData(Student student) async {
    // Prefer assignment for the selected session (promoted / current class)
    final allAssignments = await StudentClassStorage.getStudents();
    final forSession = allAssignments
        .where((a) =>
            a.admissionNo.trim().toLowerCase() ==
                student.admissionNo.trim().toLowerCase() &&
            a.session.trim() == selectedSession.trim())
        .toList();
    if (forSession.isNotEmpty) {
      studentClass = forSession.last;
    } else {
      studentClass =
          await StudentClassStorage.getStudent(student.admissionNo);
    }

    if (studentClass != null) {
      schoolFee = await SchoolFeeStorage.getFee(
        studentClass!.className,
        selectedSession,
        selectedTerm,
      );
      if (schoolFee != null) {
        totalFee = schoolFee!.totalFee;
      } else {
        totalFee = 0;
      }
      totalPaid = await StudentFeePaymentStorage.totalPaidForTerm(
        student.admissionNo,
        session: selectedSession,
        term: selectedTerm,
      );
      final paidNow = double.tryParse(amountController.text) ?? 0;
      balance = totalFee - (totalPaid + paidNow);
    } else {
      schoolFee = null;
      totalFee = 0;
      totalPaid = 0;
      balance = 0;
    }
    if (mounted) setState(() {});
  }

  void calculateBalance() {
    final paid = double.tryParse(amountController.text) ?? 0;
    balance = totalFee - (totalPaid + paid);
    setState(() {});
  }

  Future<void> savePayment() async {
    if (selectedStudent == null || studentClass == null) {
      PremiumFeedback.info(context, title: 'Select a student first');
      return;
    }
    final paid = double.tryParse(amountController.text) ?? 0;
    if (paid <= 0) {
      PremiumFeedback.info(context, title: 'Enter amount paying');
      return;
    }
    setState(() => saving = true);
    final payment = StudentFeePayment(
      receiptNo: receiptNo,
      admissionNo: selectedStudent!.admissionNo,
      studentName: selectedStudent!.fullName,
      className: studentClass!.className,
      tuitionFee: schoolFee?.tuitionFee ?? 0,
      examinationFee: schoolFee?.examinationFee ?? 0,
      ictFee: schoolFee?.ictFee ?? 0,
      sportFee: schoolFee?.sportFee ?? 0,
      developmentLevy: schoolFee?.developmentLevy ?? 0,
      ptaFee: schoolFee?.ptaFee ?? 0,
      otherCharges: schoolFee?.otherCharges ?? 0,
      totalSchoolFee: totalFee,
      amountPaid: paid,
      balance: balance,
      paymentDate: DateTime.now().toString(),
      paymentMethod: paymentMethod,
      session: selectedSession,
      term: selectedTerm,
    );
    try {
      await StudentFeePaymentStorage.savePayment(payment);
      await AuditLogStorage.log(
        action: 'fee_payment',
        module: 'fees',
        description:
            'Payment ₦${paid.toStringAsFixed(0)} for ${selectedStudent!.fullName} ($receiptNo)',
        refId: receiptNo,
      );
      if (!mounted) return;
      PremiumFeedback.success(
        context,
        title: 'Payment saved',
        subtitle: 'Receipt $receiptNo',
        icon: Icons.payments_rounded,
      );
      amountController.clear();
      await generateReceipt();
      await loadStudentData(selectedStudent!);
      setState(() => saving = false);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Payment failed', subtitle: '$e');
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    studentSearchController.dispose();
    super.dispose();
  }

  List<Student> get filteredStudents {
    final q = studentSearch.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return students
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            s.admissionNo.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: const Text('Receive Payment'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          PremiumForm.header(
            context,
            title: 'Receive Payment',
            subtitle: 'Record student fee payment',
            icon: Icons.payments_rounded,
            gradient: const [Color(0xFF065F46), Color(0xFF10B981)],
          ),
          const SizedBox(height: 16),
          PremiumForm.card(
            context,
            children: [
              Text(
                'Receipt No: $receiptNo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: sessions.contains(selectedSession)
                    ? selectedSession
                    : sessions.first,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Session',
                  prefixIcon: Icon(Icons.calendar_month_rounded),
                ),
                items: sessions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  selectedSession = v;
                  if (selectedStudent != null) {
                    await loadStudentData(selectedStudent!);
                  } else {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTerm,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Term',
                  prefixIcon: Icon(Icons.event_note_rounded),
                ),
                items: terms
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  selectedTerm = v;
                  if (selectedStudent != null) {
                    await loadStudentData(selectedStudent!);
                  } else {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: studentSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search student',
                  hintText: 'Type name or admission number…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) {
                  setState(() {
                    studentSearch = v;
                    if (selectedStudent != null) {
                      final still = filteredStudents.any(
                        (s) => s.admissionNo == selectedStudent!.admissionNo,
                      );
                      if (!still) {
                        selectedStudent = null;
                        studentClass = null;
                        schoolFee = null;
                        totalFee = 0;
                        totalPaid = 0;
                        balance = 0;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              if (selectedStudent != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedStudent!.admissionNo} — ${selectedStudent!.fullName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            selectedStudent = null;
                            studentClass = null;
                            schoolFee = null;
                            totalFee = 0;
                            totalPaid = 0;
                            balance = 0;
                            studentSearch = '';
                            studentSearchController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              if (selectedStudent != null) const SizedBox(height: 8),
              if (studentSearch.trim().isNotEmpty && selectedStudent == null)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder(context)),
                  ),
                  child: filteredStudents.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No student matches',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredStudents.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final s = filteredStudents[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF059669),
                                child: Text(
                                  s.firstName.isNotEmpty
                                      ? s.firstName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                s.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                s.admissionNo,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () async {
                                selectedStudent = s;
                                studentSearchController.text = s.fullName;
                                studentSearch = s.fullName;
                                setState(() {});
                                await loadStudentData(s);
                              },
                            );
                          },
                        ),
                ),
              if (studentSearch.trim().isEmpty && selectedStudent == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Start typing to see matching students',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              if (studentClass != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Class: ${studentClass!.className}',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
                Text(
                  '$selectedSession · $selectedTerm',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
                Text(
                  schoolFee == null
                      ? 'No fee set for this class/session/term'
                      : 'Total fee: ₦${totalFee.toStringAsFixed(0)} · Paid this term: ₦${totalPaid.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: schoolFee == null
                        ? const Color(0xFFDC2626)
                        : AppColors.textSecondary(context),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Paying',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                onChanged: (_) => calculateBalance(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'POS', child: Text('POS')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => paymentMethod = v);
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Balance after payment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₦${balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PremiumForm.primaryButton(
                label: 'SAVE PAYMENT',
                onPressed: savePayment,
                loading: saving,
                icon: Icons.save_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
