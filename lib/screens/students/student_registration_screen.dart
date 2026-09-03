import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/widgets/premium_feedback.dart';
import '../../core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/nigeria_data.dart';
import '../../models/student.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_storage.dart';
import '../../core/licence_guard.dart';
import 'student_list_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final Student? student;
  final int? index;

  const StudentRegistrationScreen({super.key, this.student, this.index});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final admissionController = TextEditingController();
  final surnameController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final dobController = TextEditingController();

  final parentController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final addressController = TextEditingController();
  final stateController = TextEditingController();
  final lgaController = TextEditingController();
  final nationalityController = TextEditingController();

  final religionController = TextEditingController();
  final medicalController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  File? passportImage;

  final ImagePicker picker = ImagePicker();

  String gender = "Male";
  String bloodGroup = "O+";
  String genotype = "AA";

  String? selectedState;
  String? selectedLga;
  String selectedNationality = "Nigeria";

  // ============================================================
  // AUTO ADMISSION NUMBER
  // ============================================================

  Future<void> generateAdmissionNumber() async {
    try {
      final students = await StudentStorage.getStudents();

      final firstYear = sessionYear();

      int count = 0;

      for (final student in students) {
        if (student.admissionNo.startsWith("HSC/$firstYear/")) {
          count++;
        }
      }

      admissionController.text =
          "HSC/$firstYear/${(count + 1).toString().padLeft(4, '0')}";
    } catch (e) {
      debugPrint("Error generating admission number: $e");
    }
  }

  String sessionYear() {
    final currentYear = DateTime.now().year;

    return currentYear.toString();
  }

  // ============================================================
  // INITIALIZE EDIT DATA
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.student != null) {
      loadStudentData();
    } else {
      final currentYear = DateTime.now().year;

      nationalityController.text = "Nigeria";
      selectedNationality = "Nigeria";

      generateAdmissionNumber();

      // Keep this so the default session starts from the current year.
      // It does not affect the student model directly.
      final defaultSession = "$currentYear/${currentYear + 1}";
      debugPrint("Default session: $defaultSession");
    }
  }

  void loadStudentData() {
    final student = widget.student!;

    admissionController.text = student.admissionNo;
    surnameController.text = student.surname;
    firstNameController.text = student.firstName;
    middleNameController.text = student.middleName;
    dobController.text = student.dateOfBirth;

    parentController.text = student.parentName;
    phoneController.text = student.phone;
    emailController.text = student.email;

    addressController.text = student.address;
    stateController.text = student.state;
    lgaController.text = student.localGovernment;
    nationalityController.text = student.nationality;

    religionController.text = student.religion;
    medicalController.text = student.medicalCondition;

    gender = student.gender;
    bloodGroup = student.bloodGroup;
    genotype = student.genotype;

    selectedState = student.state.isEmpty ? null : student.state;

    selectedLga = student.localGovernment.isEmpty
        ? null
        : student.localGovernment;

    selectedNationality = student.nationality.isEmpty
        ? "Nigeria"
        : student.nationality;

    if (student.passport.isNotEmpty) {
      passportImage = File(student.passport);
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (!mounted) return;

    if (picked != null) {
      dobController.text = "${picked.day}/${picked.month}/${picked.year}";

      setState(() {});
    }
  }

  // ============================================================
  // PASSPORT PICKER
  // ============================================================

  Future<void> pickPassport() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (!mounted) return;

    if (image != null) {
      setState(() {
        passportImage = File(image.path);
      });
    }
  }

  // ============================================================
  // CHECK ICON
  // ============================================================

  Icon? buildCheckIcon(TextEditingController controller) {
    if (controller.text.trim().isEmpty) {
      return null;
    }

    return const Icon(Icons.check_circle, color: Colors.green);
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration buildDecoration({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
      suffixIcon: buildCheckIcon(controller),
    );
  }

  // ============================================================
  // SAVE STUDENT
  // ============================================================

  Future<void> saveStudent() async {
    if (!await LicenceGuard.ensureWritable(context)) return;
    if (widget.index == null) {
      if (!await LicenceGuard.ensureCanAddStudent(context)) return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final student = Student(
      admissionNo: admissionController.text.trim(),
      surname: surnameController.text.trim(),
      firstName: firstNameController.text.trim(),
      middleName: middleNameController.text.trim(),
      gender: gender,
      dateOfBirth: dobController.text.trim(),
      parentName: parentController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
      state: stateController.text.trim(),
      localGovernment: lgaController.text.trim(),
      nationality: nationalityController.text.trim(),
      religion: religionController.text.trim(),
      bloodGroup: bloodGroup,
      genotype: genotype,
      medicalCondition: medicalController.text.trim(),
      passport: passportImage?.path ?? "",
    );

    try {
      if (widget.student == null) {
        await StudentStorage.addStudent(student);
        await AuditLogStorage.log(
          action: 'student_added',
          module: 'students',
          description: 'Registered student ${student.fullName}',
          refId: student.admissionNo,
        );
      } else {
        await StudentStorage.updateStudent(widget.index!, student);
        await AuditLogStorage.log(
          action: 'student_updated',
          module: 'students',
          description: 'Updated student ${student.fullName}',
          refId: student.admissionNo,
        );
      }

      if (!mounted) return;

      final message = widget.student == null
          ? "Student Registered Successfully"
          : "Student Updated Successfully";

      if (widget.student == null) {
        PremiumFeedback.success(
          context,
          title: 'Student added successfully',
          subtitle: 'The student has been registered',
          icon: Icons.person_add_alt_1_rounded,
        );
      } else {
        PremiumFeedback.success(
          context,
          title: 'Student updated',
          subtitle: 'Changes have been saved',
        );
      }

      if (widget.student != null) {
        Navigator.pop(context);
        return;
      }

      clearForm();

      await generateAdmissionNumber();

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error saving student: $e"),
        ),
      );
    }
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void clearForm() {
    admissionController.clear();
    surnameController.clear();
    firstNameController.clear();
    middleNameController.clear();
    dobController.clear();

    parentController.clear();
    phoneController.clear();
    emailController.clear();

    addressController.clear();
    stateController.clear();
    lgaController.clear();
    nationalityController.clear();

    religionController.clear();
    medicalController.clear();

    setState(() {
      gender = "Male";
      bloodGroup = "O+";
      genotype = "AA";

      selectedState = null;
      selectedLga = null;

      selectedNationality = "Nigeria";
      nationalityController.text = "Nigeria";

      passportImage = null;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text("Student Registration"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentListScreen()),
              );
            },
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // ==================================================
              // PERSONAL INFORMATION
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "PERSONAL INFORMATION",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: admissionController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Admission Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Admission Number is required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: surnameController,
                onChanged: (_) => setState(() {}),
                decoration: buildDecoration(
                  label: "Surname",
                  icon: Icons.person,
                  controller: surnameController,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Surname is required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: firstNameController,
                onChanged: (_) => setState(() {}),
                decoration: buildDecoration(
                  label: "First Name",
                  icon: Icons.person_outline,
                  controller: firstNameController,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "First Name is required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: middleNameController,
                decoration: const InputDecoration(
                  labelText: "Middle Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_2_outlined),
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    gender = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: dobController,
                readOnly: true,
                onTap: pickDate,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // PARENT / GUARDIAN
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "PARENT / GUARDIAN INFORMATION",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: parentController,
                decoration: const InputDecoration(
                  labelText: "Parent / Guardian Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // ADDRESS INFORMATION
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ADDRESS INFORMATION",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Home Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: selectedState,
                decoration: const InputDecoration(
                  labelText: "State",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: states.map((state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedState = value;
                    selectedLga = null;

                    stateController.text = value ?? "";

                    lgaController.clear();
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: selectedLga,
                decoration: const InputDecoration(
                  labelText: "Local Government",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                items: selectedState == null
                    ? []
                    : lgasFor(selectedState!).map((lga) {
                        return DropdownMenuItem<String>(
                          value: lga,
                          child: Text(lga),
                        );
                      }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLga = value;

                    lgaController.text = value ?? "";
                  });
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // NATIONALITY
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: selectedNationality,
                decoration: const InputDecoration(
                  labelText: "Nationality",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: nationalities.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedNationality = value;
                    nationalityController.text = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // ==================================================
              // RELIGION
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "RELIGIOUS INFORMATION",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: religionController.text.isEmpty
                    ? "Islam"
                    : religionController.text,
                decoration: const InputDecoration(
                  labelText: "Religion",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mosque),
                ),
                items: const [
                  DropdownMenuItem(value: "Islam", child: Text("Islam")),
                  DropdownMenuItem(
                    value: "Christianity",
                    child: Text("Christianity"),
                  ),
                  DropdownMenuItem(
                    value: "Traditional",
                    child: Text("Traditional"),
                  ),
                  DropdownMenuItem(value: "Others", child: Text("Others")),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    religionController.text = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // ==================================================
              // MEDICAL INFORMATION
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "MEDICAL INFORMATION",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: bloodGroup,
                decoration: const InputDecoration(
                  labelText: "Blood Group",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: const [
                  DropdownMenuItem(value: "A+", child: Text("A+")),
                  DropdownMenuItem(value: "A-", child: Text("A-")),
                  DropdownMenuItem(value: "B+", child: Text("B+")),
                  DropdownMenuItem(value: "B-", child: Text("B-")),
                  DropdownMenuItem(value: "AB+", child: Text("AB+")),
                  DropdownMenuItem(value: "AB-", child: Text("AB-")),
                  DropdownMenuItem(value: "O+", child: Text("O+")),
                  DropdownMenuItem(value: "O-", child: Text("O-")),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    bloodGroup = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: genotype,
                decoration: const InputDecoration(
                  labelText: "Genotype",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.science),
                ),
                items: const [
                  DropdownMenuItem(value: "AA", child: Text("AA")),
                  DropdownMenuItem(value: "AS", child: Text("AS")),
                  DropdownMenuItem(value: "AC", child: Text("AC")),
                  DropdownMenuItem(value: "SS", child: Text("SS")),
                  DropdownMenuItem(value: "SC", child: Text("SC")),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    genotype = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: medicalController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Medical Condition / Allergy",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // PASSPORT PHOTO
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "PASSPORT PHOTOGRAPH",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: pickPassport,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: passportImage != null
                      ? FileImage(passportImage!)
                      : null,
                  child: passportImage == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Tap the photo to select a passport photograph.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // SAVE BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.student == null
                        ? "REGISTER STUDENT"
                        : "UPDATE STUDENT",
                    style: const TextStyle(fontSize: 18),
                  ),
                  onPressed: saveStudent,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    admissionController.dispose();
    surnameController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    dobController.dispose();

    parentController.dispose();
    phoneController.dispose();
    emailController.dispose();

    addressController.dispose();
    stateController.dispose();
    lgaController.dispose();
    nationalityController.dispose();

    religionController.dispose();
    medicalController.dispose();

    super.dispose();
  }
}
