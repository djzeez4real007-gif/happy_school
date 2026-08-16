// lib/services/timetable_config.dart

class TimetableSlot {
  final String name;
  final String time;
  final bool isBreak;
  final bool isShortDay;

  const TimetableSlot({
    required this.name,
    required this.time,
    this.isBreak = false,
    this.isShortDay = false,
  });

  String get displayText {
    if (isBreak) {
      return "$name - $time";
    }

    return "$name - $time";
  }
}

class TimetableConfig {
  // ============================================================
  // SCHOOL DAYS
  // ============================================================

  static const List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  // ============================================================
  // STANDARD MONDAY - THURSDAY SCHEDULE
  //
  // You can change these times later without touching the
  // timetable form screen.
  // ============================================================

  static const List<TimetableSlot> mondayToThursday = [
    TimetableSlot(name: "Period 1", time: "8:00 AM - 8:45 AM"),
    TimetableSlot(name: "Period 2", time: "8:45 AM - 9:30 AM"),
    TimetableSlot(name: "Period 3", time: "9:30 AM - 10:15 AM"),
    TimetableSlot(
      name: "Short Break",
      time: "10:15 AM - 10:30 AM",
      isBreak: true,
    ),
    TimetableSlot(name: "Period 4", time: "10:30 AM - 11:15 AM"),
    TimetableSlot(name: "Period 5", time: "11:15 AM - 12:00 PM"),
    TimetableSlot(
      name: "Long Break",
      time: "12:00 PM - 12:30 PM",
      isBreak: true,
    ),
    TimetableSlot(name: "Period 6", time: "12:30 PM - 1:15 PM"),
    TimetableSlot(name: "Period 7", time: "1:15 PM - 2:00 PM"),
    TimetableSlot(name: "Period 8", time: "2:00 PM - 2:45 PM"),
  ];

  // ============================================================
  // FRIDAY SCHEDULE
  //
  // Friday finishes earlier.
  // ============================================================

  static const List<TimetableSlot> friday = [
    TimetableSlot(
      name: "Period 1",
      time: "8:00 AM - 8:40 AM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 2",
      time: "8:40 AM - 9:20 AM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 3",
      time: "9:20 AM - 10:00 AM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Short Break",
      time: "10:00 AM - 10:15 AM",
      isBreak: true,
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 4",
      time: "10:15 AM - 10:55 AM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 5",
      time: "10:55 AM - 11:35 AM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Long Break",
      time: "11:35 AM - 12:05 PM",
      isBreak: true,
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 6",
      time: "12:05 PM - 12:45 PM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 7",
      time: "12:45 PM - 1:25 PM",
      isShortDay: true,
    ),
    TimetableSlot(
      name: "Period 8",
      time: "1:25 PM - 2:05 PM",
      isShortDay: true,
    ),
  ];

  // ============================================================
  // GET SLOTS FOR A DAY
  // ============================================================

  static List<TimetableSlot> getSlotsForDay(String day) {
    if (day == "Friday") {
      return friday;
    }

    return mondayToThursday;
  }

  // ============================================================
  // GET PERIOD/BREAK DISPLAY VALUES
  // ============================================================

  static List<String> getPeriodValues(String day) {
    return getSlotsForDay(day).map((slot) => slot.displayText).toList();
  }

  // ============================================================
  // SESSIONS
  //
  // Includes future sessions well beyond 2030.
  // ============================================================

  static List<String> get sessions {
    final currentYear = DateTime.now().year;

    final List<String> result = [];

    for (int year = 2026; year <= currentYear + 10; year++) {
      result.add("$year/${year + 1}");
    }

    return result;
  }

  // ============================================================
  // TERMS
  // ============================================================

  static const List<String> terms = ["First Term", "Second Term", "Third Term"];
}
