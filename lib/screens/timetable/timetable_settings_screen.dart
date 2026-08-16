import 'package:flutter/material.dart';

import '../../services/timetable_settings_storage.dart';

class TimetableSettingsScreen extends StatefulWidget {
  const TimetableSettingsScreen({super.key});

  @override
  State<TimetableSettingsScreen> createState() =>
      _TimetableSettingsScreenState();
}

class _TimetableSettingsScreenState extends State<TimetableSettingsScreen> {
  bool loading = true;
  bool saving = false;

  bool shortBreakEnabled = true;
  bool longBreakEnabled = true;

  int shortBreakAfterPeriod = 2;
  int shortBreakDuration = 20;

  int longBreakAfterPeriod = 5;
  int longBreakDuration = 40;

  List<PeriodTime> mondayThursdayPeriods = [];
  List<PeriodTime> fridayPeriods = [];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    await TimetableSettingsStorage.initialize();

    final mondayThursday =
        await TimetableSettingsStorage.getMondayThursdayPeriods();

    final friday = await TimetableSettingsStorage.getFridayPeriods();

    final shortEnabled = await TimetableSettingsStorage.getShortBreakEnabled();

    final shortAfter =
        await TimetableSettingsStorage.getShortBreakAfterPeriod();

    final shortDuration =
        await TimetableSettingsStorage.getShortBreakDuration();

    final longEnabled = await TimetableSettingsStorage.getLongBreakEnabled();

    final longAfter = await TimetableSettingsStorage.getLongBreakAfterPeriod();

    final longDuration = await TimetableSettingsStorage.getLongBreakDuration();

    if (!mounted) return;

    setState(() {
      mondayThursdayPeriods = mondayThursday
          .map(
            (e) => PeriodTime(
              period: (e["period"] as num).toInt(),
              start: e["start"]?.toString() ?? "",
              end: e["end"]?.toString() ?? "",
            ),
          )
          .toList();

      fridayPeriods = friday
          .map(
            (e) => PeriodTime(
              period: (e["period"] as num).toInt(),
              start: e["start"]?.toString() ?? "",
              end: e["end"]?.toString() ?? "",
            ),
          )
          .toList();

      shortBreakEnabled = shortEnabled;
      shortBreakAfterPeriod = shortAfter;
      shortBreakDuration = shortDuration;

      longBreakEnabled = longEnabled;
      longBreakAfterPeriod = longAfter;
      longBreakDuration = longDuration;

      loading = false;
    });
  }

  Future<void> saveSettings() async {
    setState(() {
      saving = true;
    });

    try {
      await TimetableSettingsStorage.saveSettings(
        mondayThursdayPeriods: mondayThursdayPeriods
            .map((e) => e.toMap())
            .toList(),
        fridayPeriods: fridayPeriods.map((e) => e.toMap()).toList(),
        shortBreakEnabled: shortBreakEnabled,
        shortBreakAfterPeriod: shortBreakAfterPeriod,
        shortBreakDuration: shortBreakDuration,
        longBreakEnabled: longBreakEnabled,
        longBreakAfterPeriod: longBreakAfterPeriod,
        longBreakDuration: longBreakDuration,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Timetable settings saved successfully."),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Unable to save settings: $e"),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      saving = false;
    });
  }

  Future<void> addFridayPeriod() async {
    setState(() {
      final nextPeriod = fridayPeriods.length + 1;

      fridayPeriods.add(
        PeriodTime(period: nextPeriod, start: "8:00 AM", end: "8:40 AM"),
      );
    });
  }

  void removeFridayPeriod() {
    if (fridayPeriods.length <= 1) return;

    setState(() {
      fridayPeriods.removeLast();

      for (int i = 0; i < fridayPeriods.length; i++) {
        fridayPeriods[i].period = i + 1;
      }
    });
  }

  void updatePeriod(PeriodTime period, String value, bool start) {
    setState(() {
      if (start) {
        period.start = value;
      } else {
        period.end = value;
      }
    });
  }

  Widget buildPeriodList(String title, List<PeriodTime> periods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...periods.map(
          (period) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Period ${period.period}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: period.start,
                          decoration: const InputDecoration(
                            labelText: "Start Time",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          onChanged: (value) {
                            updatePeriod(period, value, true);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: period.end,
                          decoration: const InputDecoration(
                            labelText: "End Time",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                          ),
                          onChanged: (value) {
                            updatePeriod(period, value, false);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBreakSettings({
    required String title,
    required IconData icon,
    required Color color,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required int afterPeriod,
    required ValueChanged<int> onAfterPeriodChanged,
    required int duration,
    required ValueChanged<int> onDurationChanged,
  }) {
    final maxPeriod = mondayThursdayPeriods.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(icon, color: color),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              value: enabled,
              onChanged: onEnabledChanged,
            ),
            if (enabled) ...[
              const Divider(),
              DropdownButtonFormField<int>(
                initialValue: afterPeriod > maxPeriod ? maxPeriod : afterPeriod,
                decoration: const InputDecoration(
                  labelText: "After Period",
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  maxPeriod,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text("After Period ${index + 1}"),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    onAfterPeriodChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: duration,
                decoration: const InputDecoration(
                  labelText: "Break Duration",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 10, child: Text("10 minutes")),
                  DropdownMenuItem(value: 15, child: Text("15 minutes")),
                  DropdownMenuItem(value: 20, child: Text("20 minutes")),
                  DropdownMenuItem(value: 30, child: Text("30 minutes")),
                  DropdownMenuItem(value: 40, child: Text("40 minutes")),
                  DropdownMenuItem(value: 45, child: Text("45 minutes")),
                  DropdownMenuItem(value: 60, child: Text("60 minutes")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onDurationChanged(value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Timetable Settings")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Timetable Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "School Timetable Configuration",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Set the periods, school breaks and Friday schedule.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            buildPeriodList("Monday – Thursday", mondayThursdayPeriods),

            const SizedBox(height: 24),

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Most schools can use up to 8 periods from Monday to Thursday. You can adjust the times to match your school's actual timetable.",
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            buildPeriodList("Friday Schedule", fridayPeriods),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: addFridayPeriod,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Friday Period"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: fridayPeriods.length <= 1
                        ? null
                        : removeFridayPeriod,
                    icon: const Icon(Icons.remove),
                    label: const Text("Remove Period"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Break Settings",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            buildBreakSettings(
              title: "Short Break",
              icon: Icons.free_breakfast,
              color: Colors.orange,
              enabled: shortBreakEnabled,
              onEnabledChanged: (value) {
                setState(() {
                  shortBreakEnabled = value;
                });
              },
              afterPeriod: shortBreakAfterPeriod,
              onAfterPeriodChanged: (value) {
                setState(() {
                  shortBreakAfterPeriod = value;
                });
              },
              duration: shortBreakDuration,
              onDurationChanged: (value) {
                setState(() {
                  shortBreakDuration = value;
                });
              },
            ),

            const SizedBox(height: 12),

            buildBreakSettings(
              title: "Long Break",
              icon: Icons.restaurant,
              color: Colors.green,
              enabled: longBreakEnabled,
              onEnabledChanged: (value) {
                setState(() {
                  longBreakEnabled = value;
                });
              },
              afterPeriod: longBreakAfterPeriod,
              onAfterPeriodChanged: (value) {
                setState(() {
                  longBreakAfterPeriod = value;
                });
              },
              duration: longBreakDuration,
              onDurationChanged: (value) {
                setState(() {
                  longBreakDuration = value;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saving ? null : saveSettings,
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
                  saving ? "Saving..." : "SAVE TIMETABLE SETTINGS",
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class PeriodTime {
  int period;
  String start;
  String end;

  PeriodTime({required this.period, required this.start, required this.end});

  Map<String, dynamic> toMap() {
    return {"period": period, "start": start, "end": end};
  }
}
