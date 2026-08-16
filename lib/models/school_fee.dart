class SchoolFee {
  final String className;

  final double tuitionFee;
  final double examinationFee;
  final double ptaFee;
  final double ictFee;
  final double sportFee;
  final double developmentLevy;
  final double otherCharges;

  final String session;
  final String term;

  SchoolFee({
    required this.className,
    required this.tuitionFee,
    required this.examinationFee,
    required this.ptaFee,
    required this.ictFee,
    required this.sportFee,
    required this.developmentLevy,
    required this.otherCharges,
    required this.session,
    required this.term,
  });

  // TOTAL SCHOOL FEE
  double get totalFee {
    return tuitionFee +
        examinationFee +
        ptaFee +
        ictFee +
        sportFee +
        developmentLevy +
        otherCharges;
  }

  Map<String, dynamic> toMap() {
    return {
      "className": className,
      "tuitionFee": tuitionFee,
      "examinationFee": examinationFee,
      "ptaFee": ptaFee,
      "ictFee": ictFee,
      "sportFee": sportFee,
      "developmentLevy": developmentLevy,
      "otherCharges": otherCharges,
      "session": session,
      "term": term,
    };
  }

  factory SchoolFee.fromMap(Map<String, dynamic> map) {
    return SchoolFee(
      className: map["className"] ?? "",

      tuitionFee: (map["tuitionFee"] ?? 0).toDouble(),

      examinationFee: (map["examinationFee"] ?? 0).toDouble(),

      ptaFee: (map["ptaFee"] ?? 0).toDouble(),

      ictFee: (map["ictFee"] ?? 0).toDouble(),

      sportFee: (map["sportFee"] ?? 0).toDouble(),

      developmentLevy: (map["developmentLevy"] ?? 0).toDouble(),

      otherCharges: (map["otherCharges"] ?? 0).toDouble(),

      session: map["session"] ?? "2026/2027",

      term: map["term"] ?? "First Term",
    );
  }
}
