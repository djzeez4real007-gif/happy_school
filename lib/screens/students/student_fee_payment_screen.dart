import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
  String receiptNo = '';
  String paymentMethod = 'Cash';
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
    studentClass = await StudentClassStorage.getStudent(student.admissionNo);
    if (studentClass != null) {
      schoolFee = await SchoolFeeStorage.getFee(
        studentClass!.className,
        '2026/2027',
        'First Term',
      );
      if (schoolFee != null) {
        totalFee = schoolFee!.tuitionFee +
            schoolFee!.developmentLevy +
            schoolFee!.examinationFee +
            schoolFee!.sportFee +
            schoolFee!.ictFee +
            schoolFee!.ptaFee +
            schoolFee!.otherCharges;
      } else {
        totalFee = 0;
      }
      totalPaid =
          await StudentFeePaymentStorage.totalPaid(student.admissionNo);
      balance = totalFee - totalPaid;
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
      session: '2026/2027',
      term: 'First Term',
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
    super.dispose();
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
              DropdownButtonFormField<Student>(
                value: selectedStudent,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Student',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                items: students
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.admissionNo} - ${s.fullName}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  selectedStudent = value;
                  if (value != null) await loadStudentData(value);
                },
              ),
              if (studentClass != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Class: ${studentClass!.className}',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
                Text(
                  'Total fee: ₦${totalFee.toStringAsFixed(0)} · Paid: ₦${totalPaid.toStringAsFixed(0)}',
                  style: TextStyle(color: AppColors.textSecondary(context)),
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
