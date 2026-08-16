import '../models/student_fee_payment.dart';
import 'student_fee_payment_storage.dart';

class FeesDashboardService {
  //=========================
  // TOTAL MONEY RECEIVED
  //=========================
  static Future<double> totalFeesCollected() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    double total = 0;

    for (final payment in payments) {
      total += payment.amountPaid;
    }

    return total;
  }

  //=========================
  // TOTAL OUTSTANDING
  //=========================
  static Future<double> totalOutstanding() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    double total = 0;

    for (final payment in payments) {
      total += payment.balance;
    }

    return total;
  }

  //=========================
  // NUMBER OF PAYMENTS
  //=========================
  static Future<int> totalPayments() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    return payments.length;
  }

  //=========================
  // UNIQUE STUDENTS WHO PAID
  //=========================
  static Future<int> totalStudentsPaid() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    final students = <String>{};

    for (final payment in payments) {
      students.add(payment.admissionNo);
    }

    return students.length;
  }

  //=========================
  // TOTAL DEBTORS
  //=========================
  static Future<int> totalDebtors() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    final debtors = <String>{};

    for (final payment in payments) {
      if (payment.balance > 0) {
        debtors.add(payment.admissionNo);
      }
    }

    return debtors.length;
  }

  //=========================
  // RECENT PAYMENTS
  //=========================
  static Future<List<StudentFeePayment>> recentPayments() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    if (payments.length <= 5) {
      return payments;
    }

    return payments.take(5).toList();
  }

  static Future<double> collectionPercentage() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    if (payments.isEmpty) return 0;

    double collected = 0;
    double total = 0;

    for (final payment in payments) {
      collected += payment.amountPaid;
      total += payment.totalSchoolFee;
    }

    if (total == 0) return 0;

    return (collected / total) * 100;
  }

  static Future<double> todayCollection() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    final today = DateTime.now();

    double total = 0;

    for (final payment in payments) {
      try {
        final date = DateTime.parse(payment.paymentDate);

        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          total += payment.amountPaid;
        }
      } catch (_) {}
    }

    return total;
  }
}
