import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../models/school_fee.dart';
import '../../models/school_class.dart';
import '../../services/class_storage.dart';
import '../../services/school_fee_storage.dart';

class SchoolFeeSettingsScreen extends StatefulWidget {
  const SchoolFeeSettingsScreen({super.key});

  @override
  State<SchoolFeeSettingsScreen> createState() =>
      _SchoolFeeSettingsScreenState();
}

class _SchoolFeeSettingsScreenState extends State<SchoolFeeSettingsScreen> {
  List<SchoolClass> classes = [];
  List<SchoolFee> fees = [];

  SchoolClass? selectedClass;

  final tuitionController = TextEditingController();
  final examController = TextEditingController();
  final ptaController = TextEditingController();
  final ictController = TextEditingController();
  final sportController = TextEditingController();
  final developmentController = TextEditingController();
  final otherController = TextEditingController();

  String session = "2026/2027";
  String term = "First Term";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    classes = await ClassStorage.getClasses();
    fees = await SchoolFeeStorage.getFees();

    if (mounted) {
      setState(() {});
    }
  }

  double get total {
    return (double.tryParse(tuitionController.text) ?? 0) +
        (double.tryParse(examController.text) ?? 0) +
        (double.tryParse(ptaController.text) ?? 0) +
        (double.tryParse(ictController.text) ?? 0) +
        (double.tryParse(sportController.text) ?? 0) +
        (double.tryParse(developmentController.text) ?? 0) +
        (double.tryParse(otherController.text) ?? 0);
  }

  Future<void> saveFee() async {
    if (selectedClass == null) return;

    final fee = SchoolFee(
      className: selectedClass!.fullClassName,
      tuitionFee: double.tryParse(tuitionController.text) ?? 0,
      examinationFee: double.tryParse(examController.text) ?? 0,
      ptaFee: double.tryParse(ptaController.text) ?? 0,
      ictFee: double.tryParse(ictController.text) ?? 0,
      sportFee: double.tryParse(sportController.text) ?? 0,
      developmentLevy: double.tryParse(developmentController.text) ?? 0,
      otherCharges: double.tryParse(otherController.text) ?? 0,
      session: session,
      term: term,
    );

    await SchoolFeeStorage.saveFee(fee);

    tuitionController.clear();
    examController.clear();
    ptaController.clear();
    ictController.clear();
    sportController.clear();
    developmentController.clear();
    otherController.clear();

    selectedClass = null;

    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("School fee saved successfully")),
    );
  }

  Widget feeField(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
          prefixText: "₦ ",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBack.leading(context),title: const Text("School Fee Settings")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<SchoolClass>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(
                      labelText: "Class",
                      border: OutlineInputBorder(),
                    ),
                    items: classes.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.fullClassName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  feeField("Tuition Fee", tuitionController),

                  feeField("Examination Fee", examController),

                  feeField("PTA Fee", ptaController),

                  feeField("ICT Fee", ictController),

                  feeField("Sport Fee", sportController),

                  feeField("Development Levy", developmentController),

                  feeField("Other Charges", otherController),

                  Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      title: const Text(
                        "TOTAL SCHOOL FEE",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        "₦ ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: saveFee,
                      icon: const Icon(Icons.save),
                      label: const Text("SAVE SCHOOL FEE"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          Expanded(
            child: fees.isEmpty
                ? const Center(child: Text("No School Fees Added"))
                : ListView.builder(
                    itemCount: fees.length,
                    itemBuilder: (_, index) {
                      final fee = fees[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.school),
                          title: Text(fee.className),
                          subtitle: Text(
                            "₦ ${fee.totalFee.toStringAsFixed(2)}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await SchoolFeeStorage.deleteFee(index);
                              await loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
