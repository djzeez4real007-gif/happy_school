import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/school_class.dart';
import '../../models/school_fee.dart';
import '../../services/audit_log_storage.dart';
import '../../services/class_storage.dart';
import '../../services/school_fee_storage.dart';

class SchoolFeeScreen extends StatefulWidget {
  const SchoolFeeScreen({super.key});

  @override
  State<SchoolFeeScreen> createState() => _SchoolFeeScreenState();
}

class _SchoolFeeScreenState extends State<SchoolFeeScreen> {
  final tuitionController = TextEditingController();
  final examController = TextEditingController();
  final sportController = TextEditingController();
  final ictController = TextEditingController();
  final ptaController = TextEditingController();
  final developmentController = TextEditingController();
  final otherController = TextEditingController();

  List<SchoolClass> classes = [];
  List<SchoolFee> fees = [];
  SchoolClass? selectedClass;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    classes = await ClassStorage.getClasses();
    fees = await SchoolFeeStorage.getFees();
    if (mounted) setState(() {});
  }

  double value(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> saveFee() async {
    if (selectedClass == null) {
      PremiumFeedback.info(context, title: 'Select a class first');
      return;
    }
    setState(() => saving = true);
    try {
      await SchoolFeeStorage.saveFee(
        SchoolFee(
          className: selectedClass!.fullClassName,
          tuitionFee: value(tuitionController),
          examinationFee: value(examController),
          sportFee: value(sportController),
          ictFee: value(ictController),
          ptaFee: value(ptaController),
          developmentLevy: value(developmentController),
          otherCharges: value(otherController),
          session: '2026/2027',
          term: 'First Term',
        ),
      );
      tuitionController.clear();
      examController.clear();
      sportController.clear();
      ictController.clear();
      ptaController.clear();
      developmentController.clear();
      otherController.clear();
      selectedClass = null;
      await loadData();
      if (!mounted) return;
      setState(() => saving = false);
      await AuditLogStorage.log(
        action: 'fee_settings_saved',
        module: 'fees',
        description: 'Updated school fee settings',
      );
      PremiumFeedback.success(
        context,
        title: 'School fee saved successfully',
        subtitle: 'Fee structure updated',
        icon: Icons.payments_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Save failed', subtitle: '$e');
    }
  }

  Widget feeField(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: const Icon(Icons.payments_outlined),
        ),
      ),
    );
  }

  @override
  void dispose() {
    tuitionController.dispose();
    examController.dispose();
    sportController.dispose();
    ictController.dispose();
    ptaController.dispose();
    developmentController.dispose();
    otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('School Fee Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          PremiumForm.header(
            context,
            title: 'Fee Settings',
            subtitle: 'Set fee amounts per class',
            icon: Icons.settings_rounded,
            gradient: const [Color(0xFF065F46), Color(0xFF10B981)],
          ),
          const SizedBox(height: 16),
          PremiumForm.card(
            context,
            children: [
              DropdownButtonFormField<SchoolClass>(
                value: selectedClass,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Class',
                  prefixIcon: Icon(Icons.class_rounded),
                ),
                items: classes
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.fullClassName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedClass = v),
              ),
              const SizedBox(height: 16),
              feeField('Tuition Fee', tuitionController),
              feeField('Examination Fee', examController),
              feeField('Sport Fee', sportController),
              feeField('ICT Fee', ictController),
              feeField('PTA Fee', ptaController),
              feeField('Development Levy', developmentController),
              feeField('Other Charges', otherController),
              const SizedBox(height: 8),
              PremiumForm.primaryButton(
                label: 'SAVE SCHOOL FEE',
                onPressed: saveFee,
                loading: saving,
                icon: Icons.save_rounded,
              ),
            ],
          ),
          if (fees.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Saved fee structures',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            ...fees.map((fee) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.payments_rounded, color: Color(0xFF059669)),
                  title: Text(
                    fee.className,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  subtitle: Text('${fee.session} · ${fee.term}'),
                  trailing: Text(
                    '₦${fee.totalFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
