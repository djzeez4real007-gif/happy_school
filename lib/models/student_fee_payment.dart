class StudentFeePayment {
  final String receiptNo;
  final String admissionNo;
  final String studentName;
  final String className;

  final double tuitionFee;
  final double examinationFee;
  final double ictFee;
  final double sportFee;
  final double developmentLevy;
  final double ptaFee;
  final double otherCharges;

  final double totalSchoolFee;

  /// Cash/POS/transfer actually received (NOT including discount).
  final double amountPaid;

  /// Waiver / scholarship / discount for this receipt. Reduces balance
  /// but is NOT counted as money collected.
  final double discountAmount;

  final double balance;

  final String paymentDate;
  final String paymentMethod;

  final String session;
  final String term;

  StudentFeePayment({
    required this.receiptNo,
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.tuitionFee,
    required this.examinationFee,
    required this.ictFee,
    required this.sportFee,
    required this.developmentLevy,
    required this.ptaFee,
    required this.otherCharges,
    required this.totalSchoolFee,
    required this.amountPaid,
    this.discountAmount = 0,
    required this.balance,
    required this.paymentDate,
    required this.paymentMethod,
    required this.session,
    required this.term,
  });

  Map<String, dynamic> toMap() {
    return {
      "receiptNo": receiptNo,
      "admissionNo": admissionNo,
      "studentName": studentName,
      "className": className,
      "tuitionFee": tuitionFee,
      "examinationFee": examinationFee,
      "ictFee": ictFee,
      "sportFee": sportFee,
      "developmentLevy": developmentLevy,
      "ptaFee": ptaFee,
      "otherCharges": otherCharges,
      "totalSchoolFee": totalSchoolFee,
      "amountPaid": amountPaid,
      "discountAmount": discountAmount,
      "balance": balance,
      "paymentDate": paymentDate,
      "paymentMethod": paymentMethod,
      "session": session,
      "term": term,
    };
  }

  factory StudentFeePayment.fromMap(Map<String, dynamic> map) {
    return StudentFeePayment(
      receiptNo: map["receiptNo"] ?? "",
      admissionNo: map["admissionNo"] ?? "",
      studentName: map["studentName"] ?? "",
      className: map["className"] ?? "",
      tuitionFee: (map["tuitionFee"] ?? 0).toDouble(),
      examinationFee: (map["examinationFee"] ?? 0).toDouble(),
      ictFee: (map["ictFee"] ?? 0).toDouble(),
      sportFee: (map["sportFee"] ?? 0).toDouble(),
      developmentLevy: (map["developmentLevy"] ?? 0).toDouble(),
      ptaFee: (map["ptaFee"] ?? 0).toDouble(),
      otherCharges: (map["otherCharges"] ?? 0).toDouble(),
      totalSchoolFee: (map["totalSchoolFee"] ?? 0).toDouble(),
      amountPaid: (map["amountPaid"] ?? 0).toDouble(),
      discountAmount: (map["discountAmount"] ?? 0).toDouble(),
      balance: (map["balance"] ?? 0).toDouble(),
      paymentDate: map["paymentDate"] ?? "",
      paymentMethod: map["paymentMethod"] ?? "",
      session: map["session"] ?? "",
      term: map["term"] ?? "",
    );
  }
}
