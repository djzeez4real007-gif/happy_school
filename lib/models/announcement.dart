class Announcement {
  final String id;
  final String title;
  final String message;
  final String date;
  final bool pinned;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.pinned,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "message": message,
      "date": date,
      "pinned": pinned,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map["id"] ?? "",
      title: map["title"] ?? "",
      message: map["message"] ?? "",
      date: map["date"] ?? "",
      pinned: map["pinned"] ?? false,
    );
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    String? date,
    bool? pinned,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      pinned: pinned ?? this.pinned,
    );
  }
}
