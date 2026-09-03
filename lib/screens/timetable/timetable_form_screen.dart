// lib/screens/timetable/timetable_form_screen.dart

import 'package:flutter/material.dart';

import '../../models/timetable.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';

import '../../services/audit_log_storage.dart';
import '../../services/timetable_storage.dart';
import '../../services/class_storage.dart';
import '../../services/subject_storage.dart';
import '../../services/teacher_storage.dart';
import '../../services/timetable_settings_storage.dart';

class TimetableFormScreen extends StatefulWidget {
  final Timetable? timetable;
  final int? index;

  const TimetableFormScreen({super.key, this.timetable, this.index});

  @override
  State<TimetableFormScreen> createState() => _TimetableFormScreenState();
}

class _TimetableFormScreenState extends State<TimetableFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<SchoolClass> classes = [];
  List<Subject> subjects = [];
  List<Teacher> teachers = [];

  String selectedDay = "Monday";
  String selectedPeriod = "";

  String selectedSession = "2026/2027";
  String selectedTerm = "First Term";

  SchoolClass? selectedClass;
  Subject? selectedSubject;
  Teacher? selectedTeacher;

  final roomController = TextEditingController();

  // ============================================================
  // DAYS
  // ============================================================

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  // ============================================================
  // PERIOD CONFIGURATION
  //
  // Monday - Thursday
  // ============================================================

  List<PeriodTime> normalPeriods = [];
  List<PeriodTime> fridayPeriods = [];

  // ============================================================
  // SESSIONS
  // ============================================================

  final List<String> sessions = [
    "2026/2027",
    "2027/2028",
    "2028/2029",
    "2029/2030",
    "2030/2031",
    "2031/2032",
    "2032/2033",
    "2033/2034",
    "2034/2035",
    "2035/2036",
    "2036/2037",
    "2037/2038",
    "2038/2039",
    "2039/2040",
    "2040/2041",
  ];

  // ============================================================
  // TERMS
  // ============================================================

  final List<String> terms = ["First Term", "Second Term", "Third Term"];

  bool loading = true;
  bool saving = false;

  // ============================================================
  // CURRENT PERIOD LIST
  // ============================================================

  List<PeriodTime> get availablePeriods {
    if (selectedDay == "Friday") {
      return fridayPeriods;
    }

    return normalPeriods;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  TimeOfDay parseTimeOfDay(String value) {
    try {
      final v = value.trim().toUpperCase();
      final isPm = v.contains('PM');
      final isAm = v.contains('AM');
      final cleaned = v.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = cleaned.split(':');
      var hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _loadPeriodsFromSettings() async {
    final mon = await TimetableSettingsStorage.getMondayThursdayPeriods();
    final fri = await TimetableSettingsStorage.getFridayPeriods();

    normalPeriods = mon.map((m) {
      final n = m['period'] ?? 1;
      return PeriodTime(
        period: 'Period $n',
        start: parseTimeOfDay(m['start']?.toString() ?? '8:00 AM'),
        end: parseTimeOfDay(m['end']?.toString() ?? '8:45 AM'),
      );
    }).toList();

    fridayPeriods = fri.map((m) {
      final n = m['period'] ?? 1;
      return PeriodTime(
        period: 'Period $n',
        start: parseTimeOfDay(m['start']?.toString() ?? '8:00 AM'),
        end: parseTimeOfDay(m['end']?.toString() ?? '8:40 AM'),
      );
    }).toList();
  }

  Future<void> loadData() async {
    try {
      await _loadPeriodsFromSettings();
      final loadedClasses = await ClassStorage.getClasses();

      final loadedSubjects = await SubjectStorage.getSubjects();

      final loadedTeachers = await TeacherStorage.getTeachers();

      if (!mounted) return;

      setState(() {
        classes = loadedClasses;
        subjects = loadedSubjects;
        teachers = loadedTeachers;
      });

      // ========================================================
      // EDIT EXISTING TIMETABLE
      // ========================================================

      if (widget.timetable != null) {
        final timetable = widget.timetable!;

        SchoolClass? timetableClass;

        for (final schoolClass in loadedClasses) {
          if (schoolClass.fullClassName == timetable.className) {
            timetableClass = schoolClass;
            break;
          }
        }

        Subject? timetableSubject;

        for (final subject in loadedSubjects) {
          if (subject.subjectName == timetable.subject) {
            timetableSubject = subject;
            break;
          }
        }

        Teacher? timetableTeacher;

        for (final teacher in loadedTeachers) {
          if (teacher.fullName == timetable.teacher) {
            timetableTeacher = teacher;
            break;
          }
        }

        if (!mounted) return;

        setState(() {
          selectedDay = timetable.day;
          selectedPeriod = timetable.period;
          selectedSession = timetable.session;
          selectedTerm = timetable.term;

          selectedClass = timetableClass;
          selectedSubject = timetableSubject;
          selectedTeacher = timetableTeacher;

          roomController.text = timetable.room;
        });
      } else {
        // ======================================================
        // NEW ENTRY
        // ======================================================

        if (availablePeriods.isNotEmpty) {
          selectedPeriod = formatPeriod(availablePeriods.first);
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to load timetable data: $e")),
      );
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? "AM" : "PM";

    return "$hour:$minute $period";
  }

  // ============================================================
  // FORMAT PERIOD
  // ============================================================

  String formatPeriod(PeriodTime period) {
    return "${period.period}: "
        "${formatTime(period.start)} - "
        "${formatTime(period.end)}";
  }

  // ============================================================
  // FIND PERIOD FROM SAVED VALUE
  // ============================================================

  PeriodTime? findSelectedPeriod() {
    for (final period in availablePeriods) {
      if (formatPeriod(period) == selectedPeriod) {
        return period;
      }
    }

    return null;
  }

  // ============================================================
  // CHANGE DAY
  // ============================================================

  void changeDay(String value) {
    setState(() {
      selectedDay = value;

      final periods = availablePeriods;

      if (periods.isNotEmpty) {
        selectedPeriod = formatPeriod(periods.first);
      } else {
        selectedPeriod = "";
      }
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveTimetable() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedClass == null) {
      showMessage("Please select a class.");
      return;
    }

    if (selectedSubject == null) {
      showMessage("Please select a subject.");
      return;
    }

    if (selectedTeacher == null) {
      showMessage("Please select a teacher.");
      return;
    }

    if (selectedPeriod.isEmpty) {
      showMessage("Please select a period.");
      return;
    }

    setState(() {
      saving = true;
    });

    // Keep "Period N" clearly so grid can match even if times differ
    var periodValue = selectedPeriod.trim();
    final periodNum = RegExp(r'Period\s*(\d+)', caseSensitive: false)
        .firstMatch(periodValue);
    if (periodNum != null) {
      periodValue =
          'Period ${periodNum.group(1)}: ${periodValue.split(':').skip(1).join(':').trim()}';
      if (!periodValue.contains(':')) {
        periodValue = 'Period ${periodNum.group(1)}';
      }
    }

    final timetable = Timetable(
      id: widget.timetable?.id ?? TimetableStorage.generateId(),

      day: selectedDay,

      period: periodValue.isNotEmpty ? periodValue : selectedPeriod,

      className: selectedClass!.fullClassName,

      subject: selectedSubject!.subjectName,

      teacher: selectedTeacher!.fullName,

      room: roomController.text.trim(),

      session: selectedSession,

      term: selectedTerm,
    );

    try {
      if (widget.index == null) {
        await TimetableStorage.addTimetable(timetable);
      await AuditLogStorage.log(
        action: 'timetable_saved',
        module: 'timetable',
        description: 'Saved timetable entry',
      );
      } else {
        await TimetableStorage.updateTimetable(widget.index!, timetable);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            widget.index == null
                ? "Timetable entry added successfully."
                : "Timetable entry updated successfully.",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      showMessage("Unable to save timetable entry: $e");
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // PERIOD DROPDOWN
  // ============================================================

  Widget buildPeriodDropdown() {
    final periods = availablePeriods;

    if (periods.isEmpty) {
      return const Text("No periods configured for this day.");
    }

    PeriodTime? currentPeriod = findSelectedPeriod();

    if (currentPeriod == null) {
      currentPeriod = periods.first;

      selectedPeriod = formatPeriod(currentPeriod);
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedPeriod,
      decoration: const InputDecoration(
        labelText: "Period / Time",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.access_time),
      ),
      items: periods.map((period) {
        final value = formatPeriod(period);

        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedPeriod = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select a period";
        }

        return null;
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final editing = widget.timetable != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? "Edit Timetable" : "Add Timetable")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ==================================================
                    // DAY
                    // ==================================================
                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(
                        labelText: "Day",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: days.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        changeDay(value);
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // PERIOD
                    // ==================================================
                    buildPeriodDropdown(),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        selectedDay == "Friday"
                            ? "Friday uses the shorter school timetable."
                            : "Monday–Thursday use the normal school timetable.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // CLASS
                    // ==================================================
                    DropdownButtonFormField<SchoolClass>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(
                        labelText: "Class",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: classes.map((schoolClass) {
                        return DropdownMenuItem<SchoolClass>(
                          value: schoolClass,
                          child: Text(schoolClass.fullClassName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return "Please select a class";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // SUBJECT
                    // ==================================================
                    DropdownButtonFormField<Subject>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: "Subject",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.menu_book),
                      ),
                      items: subjects.map((subject) {
                        return DropdownMenuItem<Subject>(
                          value: subject,
                          child: Text(subject.subjectName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return "Please select a subject";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // TEACHER
                    // ==================================================
                    DropdownButtonFormField<Teacher>(
                      initialValue: selectedTeacher,
                      decoration: const InputDecoration(
                        labelText: "Teacher",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: teachers.map((teacher) {
                        return DropdownMenuItem<Teacher>(
                          value: teacher,
                          child: Text(teacher.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTeacher = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return "Please select a teacher";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // ROOM
                    // ==================================================
                    TextFormField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: "Room / Venue",
                        hintText: "Example: Room 4",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // SESSION
                    // ==================================================
                    DropdownButtonFormField<String>(
                      initialValue: selectedSession,
                      decoration: const InputDecoration(
                        labelText: "Session",
                        border: OutlineInputBorder(),
                      ),
                      items: sessions.map((session) {
                        return DropdownMenuItem<String>(
                          value: session,
                          child: Text(session),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedSession = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // TERM
                    // ==================================================
                    DropdownButtonFormField<String>(
                      initialValue: selectedTerm,
                      decoration: const InputDecoration(
                        labelText: "Term",
                        border: OutlineInputBorder(),
                      ),
                      items: terms.map((term) {
                        return DropdownMenuItem<String>(
                          value: term,
                          child: Text(term),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedTerm = value;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // SAVE BUTTON
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : saveTimetable,
                        icon: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          saving
                              ? "Saving..."
                              : editing
                              ? "UPDATE TIMETABLE"
                              : "SAVE TIMETABLE",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
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
    roomController.dispose();

    super.dispose();
  }
}

// ============================================================
// PERIOD TIME MODEL
// ============================================================

class PeriodTime {
  final String period;
  final TimeOfDay start;
  final TimeOfDay end;

  const PeriodTime({
    required this.period,
    required this.start,
    required this.end,
  });
}
