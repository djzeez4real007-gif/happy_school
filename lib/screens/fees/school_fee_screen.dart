import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
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
  String? selectedClassName;
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  bool applyToAllTerms = false;
  bool saving = false;
  bool loadingFee = false;

  final sessions = Sessions.list();
  final terms = Sessions.terms;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final raw = await ClassStorage.getClasses();
    // Deduplicate by class display name (avoids dropdown assertion crash)
    final seen = <String>{};
    classes = [];
    for (final c in raw) {
      final key = c.fullClassName.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      classes.add(c);
    }
    classes.sort(
      (a, b) => a.fullClassName.toLowerCase().compareTo(
            b.fullClassName.toLowerCase(),
          ),
    );
    fees = await SchoolFeeStorage.getFees();
    // Drop invalid selection if class list changed
    if (selectedClassName != null &&
        !classes.any((c) => c.fullClassName == selectedClassName)) {
      selectedClassName = null;
    }
    if (mounted) setState(() {});
    await loadExistingFeeIntoForm();
  }

  void clearAmounts() {
    tuitionController.clear();
    examController.clear();
    sportController.clear();
    ictController.clear();
    ptaController.clear();
    developmentController.clear();
    otherController.clear();
  }

  Future<void> loadExistingFeeIntoForm() async {
    if (selectedClassName == null) {
      clearAmounts();
      if (mounted) setState(() {});
      return;
    }

    setState(() => loadingFee = true);
    final existing = await SchoolFeeStorage.getFee(
      selectedClassName!,
      selectedSession,
      selectedTerm,
    );

    if (existing != null) {
      tuitionController.text = _num(existing.tuitionFee);
      examController.text = _num(existing.examinationFee);
      sportController.text = _num(existing.sportFee);
      ictController.text = _num(existing.ictFee);
      ptaController.text = _num(existing.ptaFee);
      developmentController.text = _num(existing.developmentLevy);
      otherController.text = _num(existing.otherCharges);
    } else {
      clearAmounts();
    }

    if (mounted) setState(() => loadingFee = false);
  }

  String _num(double v) => v == 0 ? '' : v.toStringAsFixed(0);

  double value(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> saveFee() async {
    if (selectedClassName == null) {
      PremiumFeedback.info(context, title: 'Select a class first');
      return;
    }
    setState(() => saving = true);
    try {
      final fee = SchoolFee(
        className: selectedClassName!,
        tuitionFee: value(tuitionController),
        examinationFee: value(examController),
        sportFee: value(sportController),
        ictFee: value(ictController),
        ptaFee: value(ptaController),
        developmentLevy: value(developmentController),
        otherCharges: value(otherController),
        session: selectedSession,
        term: selectedTerm,
      );

      if (applyToAllTerms) {
        await SchoolFeeStorage.saveFeeForAllTerms(fee);
      } else {
        await SchoolFeeStorage.saveFee(fee);
      }

      await AuditLogStorage.log(
        action: 'fee_settings_saved',
        module: 'fees',
        description: applyToAllTerms
            ? 'Saved fees for ${fee.className} · $selectedSession (all terms)'
            : 'Saved fees for ${fee.className} · $selectedSession · $selectedTerm',
        refId: fee.className,
      );

      await loadData();
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.success(
        context,
        title: 'School fee saved',
        subtitle: applyToAllTerms
            ? '${fee.className} · all terms · ₦${fee.totalFee.toStringAsFixed(0)}'
            : '${fee.className} · $selectedTerm · ₦${fee.totalFee.toStringAsFixed(0)}',
        icon: Icons.payments_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Save failed', subtitle: '$e');
    }
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

  Widget feeField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '₦ ',
          prefixIcon: const Icon(Icons.payments_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleFees = fees.where((f) {
      return f.session == selectedSession;
    }).toList();

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
            title: 'School Fee Settings',
            subtitle: 'Set fees per class, session and term',
            icon: Icons.account_balance_wallet_rounded,
            gradient: const [Color(0xFF065F46), Color(0xFF10B981)],
          ),
          const SizedBox(height: 16),
          PremiumForm.card(
            context,
            children: [
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
                  await loadExistingFeeIntoForm();
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
                  await loadExistingFeeIntoForm();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: classes.any((c) => c.fullClassName == selectedClassName)
                    ? selectedClassName
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.class_rounded),
                ),
                items: classes
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.fullClassName,
                        child: Text(e.fullClassName),
                      ),
                    )
                    .toList(),
                onChanged: (v) async {
                  selectedClassName = v;
                  await loadExistingFeeIntoForm();
                },
              ),
              const SizedBox(height: 8),
              if (loadingFee)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: applyToAllTerms,
                onChanged: (v) =>
                    setState(() => applyToAllTerms = v ?? false),
                title: const Text(
                  'Apply these amounts to all 3 terms',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Useful when fees are the same every term',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              feeField('Tuition Fee', tuitionController),
              feeField('Examination Fee', examController),
              feeField('Sport Fee', sportController),
              feeField('ICT Fee', ictController),
              feeField('PTA Fee', ptaController),
              feeField('Development Levy', developmentController),
              feeField('Other Charges', otherController),
              const SizedBox(height: 8),
              PremiumForm.primaryButton(
                label: applyToAllTerms
                    ? 'SAVE FOR ALL TERMS'
                    : 'SAVE SCHOOL FEE',
                onPressed: saveFee,
                loading: saving,
                icon: Icons.save_rounded,
              ),
            ],
          ),
          if (visibleFees.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Saved fees · $selectedSession',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            ...visibleFees.map((fee) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder(context)),
                ),
                child: ListTile(
                  onTap: () async {
                    selectedClassName = fee.className;
                    selectedTerm = fee.term;
                    selectedSession = fee.session;
                    // Align to registered class name if possible
                    for (final c in classes) {
                      if (c.fullClassName.replaceAll(' ', '').toLowerCase() ==
                          fee.className.replaceAll(' ', '').toLowerCase()) {
                        selectedClassName = c.fullClassName;
                        break;
                      }
                    }
                    await loadExistingFeeIntoForm();
                  },
                  leading: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFF059669),
                  ),
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
          const SizedBox(height: 12),
          Text(
            'Note: Promoted students use the fee of their new class '
            'for the selected session and term.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
