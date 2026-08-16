class TimetablePeriod {
  final String id;
  final String day;
  final String name;
  final String startTime;
  final String endTime;
  final String type;

  TimetablePeriod({
    required this.id,
    required this.day,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.type = "Period",
  });

  bool get isBreak => type != "Period";

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "day": day,
      "name": name,
      "startTime": startTime,
      "endTime": endTime,
      "type": type,
    };
  }

  factory TimetablePeriod.fromMap(Map<String, dynamic> map) {
    return TimetablePeriod(
      id: map["id"] ?? "",
      day: map["day"] ?? "",
      name: map["name"] ?? "",
      startTime: map["startTime"] ?? "",
      endTime: map["endTime"] ?? "",
      type: map["type"] ?? "Period",
    );
  }

  String get displayTime {
    if (startTime.isEmpty && endTime.isEmpty) {
      return "";
    }

    return "$startTime - $endTime";
  }

  TimetablePeriod copyWith({
    String? id,
    String? day,
    String? name,
    String? startTime,
    String? endTime,
    String? type,
  }) {
    return TimetablePeriod(
      id: id ?? this.id,
      day: day ?? this.day,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
    );
  }
}
