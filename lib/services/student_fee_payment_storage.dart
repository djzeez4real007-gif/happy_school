import 'package:hive_flutter/hive_flutter.dart';

import '../models/student_fee_payment.dart';

class StudentFeePaymentStorage {
  static const String boxName = "student_fee_payments";

  //==========================
  // SAVE PAYMENT
  //==========================
  static Future<void> savePayment(StudentFeePayment payment) async {
    final box = Hive.box<Map>(boxName);

    await box.add(payment.toMap());
  }

  //==========================
  // GET ALL PAYMENTS
  //==========================
  static Future<List<StudentFeePayment>> getPayments() async {
    final box = Hive.box<Map>(boxName);

    return box.values
        .map((e) => StudentFeePayment.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  //==========================
  // DELETE PAYMENT
  //==========================
  static Future<void> deletePayment(int index) async {
    final box = Hive.box<Map>(boxName);

    await box.deleteAt(index);
  }

  //==========================
  // UPDATE PAYMENT
  //==========================
  static Future<void> updatePayment(
    int index,
    StudentFeePayment payment,
  ) async {
    final box = Hive.box<Map>(boxName);

    await box.putAt(index, payment.toMap());
  }

  //==========================
  // GET TOTAL PAID BY STUDENT
  //==========================
  static Future<double> totalPaid(String admissionNo) async {
    final payments = await getPayments();

    double total = 0;

    for (final payment in payments) {
      if (payment.admissionNo == admissionNo) {
        total += payment.amountPaid;
      }
    }

    return total;
  }

  /// Total paid for a student in a specific session + term.
  static Future<double> totalPaidForTerm(
    String admissionNo, {
    required String session,
    required String term,
  }) async {
    final payments = await getPayments();
    double total = 0;
    for (final payment in payments) {
      if (payment.admissionNo == admissionNo &&
          payment.session == session &&
          payment.term == term) {
        total += payment.amountPaid;
      }
    }
    return total;
  }

  /// Discounts only (not money received) for session + term.
  static Future<double> totalDiscountForTerm(
    String admissionNo, {
    required String session,
    required String term,
  }) async {
    final payments = await getPayments();
    double total = 0;
    for (final payment in payments) {
      if (payment.admissionNo == admissionNo &&
          payment.session == session &&
          payment.term == term) {
        total += payment.discountAmount;
      }
    }
    return total;
  }


  //==========================
  // GET PAYMENTS OF A STUDENT
  //==========================
  static Future<List<StudentFeePayment>> getStudentPayments(
    String admissionNo,
  ) async {
    final payments = await getPayments();

    return payments.where((e) => e.admissionNo == admissionNo).toList();
  }

  //==========================
  // GET PAYMENT BY RECEIPT
  //==========================
  static Future<StudentFeePayment?> getReceipt(String receiptNo) async {
    final payments = await getPayments();

    try {
      return payments.firstWhere((e) => e.receiptNo == receiptNo);
    } catch (_) {
      return null;
    }
  }

  //==========================
  // GENERATE RECEIPT NUMBER
  //==========================
  static Future<String> generateReceiptNumber() async {
    final box = Hive.box<Map>(boxName);

    final next = box.length + 1;

    return "RCP${next.toString().padLeft(6, '0')}";
  }
}
