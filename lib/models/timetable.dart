class Timetable {
  final String id;
  final String day;
  final String period;
  final String className;
  final String subject;
  final String teacher;
  final String room;
  final String session;
  final String term;

  Timetable({
    required this.id,
    required this.day,
    required this.period,
    required this.className,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.session,
    required this.term,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "day": day,
      "period": period,
      "className": className,
      "subject": subject,
      "teacher": teacher,
      "room": room,
      "session": session,
      "term": term,
    };
  }

  factory Timetable.fromMap(Map<String, dynamic> map) {
    return Timetable(
      id: map["id"] ?? "",
      day: map["day"] ?? "",
      period: map["period"] ?? "",
      className: map["className"] ?? "",
      subject: map["subject"] ?? "",
      teacher: map["teacher"] ?? "",
      room: map["room"] ?? "",
      session: map["session"] ?? "",
      term: map["term"] ?? "",
    );
  }

  Timetable copyWith({
    String? id,
    String? day,
    String? period,
    String? className,
    String? subject,
    String? teacher,
    String? room,
    String? session,
    String? term,
  }) {
    return Timetable(
      id: id ?? this.id,
      day: day ?? this.day,
      period: period ?? this.period,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      session: session ?? this.session,
      term: term ?? this.term,
    );
  }
}
