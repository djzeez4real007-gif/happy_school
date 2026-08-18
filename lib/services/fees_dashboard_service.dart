import '../core/utils/sessions.dart';
import '../models/student_fee_payment.dart';
import 'school_fee_storage.dart';
import 'student_class_storage.dart';
import 'student_fee_payment_storage.dart';
import 'student_storage.dart';

class FeesDashboardService {
  /// Snapshot of fee status for assigned students in a session/term.
  static Future<_FeeSnapshot> _snapshot({
    String? session,
    String? term,
  }) async {
    final sess = session ?? Sessions.current();
    final trm = term ?? 'First Term';

    final students = await StudentStorage.getStudents();
    final assignments = await StudentClassStorage.getStudents();

    int debtors = 0;
    int fullyPaid = 0;
    int withFee = 0;
    double expected = 0;
    double collected = 0;
    double outstanding = 0;

    for (final student in students) {
      try {
        final sc = assignments.firstWhere(
          (e) => e.admissionNo == student.admissionNo,
        );

        final fee = await SchoolFeeStorage.getFee(
          sc.className,
          sess,
          trm,
        );
        if (fee == null) continue;

        withFee++;
        final paid = await StudentFeePaymentStorage.totalPaidForTerm(
          student.admissionNo,
          session: sess,
          term: trm,
        );

        expected += fee.totalFee;
        collected += paid > fee.totalFee ? fee.totalFee : paid;

        final balance = fee.totalFee - paid;
        if (balance > 0.01) {
          debtors++;
          outstanding += balance;
        } else {
          fullyPaid++;
        }
      } catch (_) {
        // not assigned to a class
      }
    }

    return _FeeSnapshot(
      debtors: debtors,
      fullyPaid: fullyPaid,
      withFee: withFee,
      expected: expected,
      collectedForTerm: collected,
      outstanding: outstanding,
    );
  }

  //=========================
  // TOTAL MONEY RECEIVED (all payments ever)
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
  // TOTAL OUTSTANDING (assigned students who still owe this term)
  // Includes zero-payment students.
  //=========================
  static Future<double> totalOutstanding({
    String? session,
    String? term,
  }) async {
    final s = await _snapshot(session: session, term: term);
    return s.outstanding;
  }

  //=========================
  // NUMBER OF PAYMENTS
  //=========================
  static Future<int> totalPayments() async {
    final payments = await StudentFeePaymentStorage.getPayments();
    return payments.length;
  }

  //=========================
  // STUDENTS WHO HAVE MADE AT LEAST ONE PAYMENT
  //=========================
  static Future<int> totalStudentsPaid() async {
    final payments = await StudentFeePaymentStorage.getPayments();
    final students = <String>{};
    for (final payment in payments) {
      students.add(payment.admissionNo);
    }
    return students.length;
  }

  /// Students fully cleared for the selected session/term.
  static Future<int> totalStudentsFullyPaid({
    String? session,
    String? term,
  }) async {
    final s = await _snapshot(session: session, term: term);
    return s.fullyPaid;
  }

  //=========================
  // TOTAL DEBTORS
  // Anyone with a fee set who has not fully paid (includes ₦0 paid).
  //=========================
  static Future<int> totalDebtors({
    String? session,
    String? term,
  }) async {
    final s = await _snapshot(session: session, term: term);
    return s.debtors;
  }

  //=========================
  // RECENT PAYMENTS
  //=========================
  static Future<List<StudentFeePayment>> recentPayments() async {
    final payments = await StudentFeePaymentStorage.getPayments();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    if (payments.length <= 5) return payments;
    return payments.take(5).toList();
  }

  static Future<double> collectionPercentage({
    String? session,
    String? term,
  }) async {
    final s = await _snapshot(session: session, term: term);
    if (s.expected <= 0) return 0;
    return (s.collectedForTerm / s.expected) * 100;
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

class _FeeSnapshot {
  final int debtors;
  final int fullyPaid;
  final int withFee;
  final double expected;
  final double collectedForTerm;
  final double outstanding;

  _FeeSnapshot({
    required this.debtors,
    required this.fullyPaid,
    required this.withFee,
    required this.expected,
    required this.collectedForTerm,
    required this.outstanding,
  });
}
