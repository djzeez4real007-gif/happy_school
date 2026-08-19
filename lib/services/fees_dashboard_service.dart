import '../core/utils/sessions.dart';
import '../models/student_class.dart';
import '../models/student_fee_payment.dart';
import 'school_fee_storage.dart';
import 'student_class_storage.dart';
import 'student_fee_payment_storage.dart';
import 'student_storage.dart';

class FeesDashboardService {
  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

  static bool _inactive(String className) {
    final c = className.trim().toLowerCase();
    return c == 'graduated' || c == 'left' || c == 'withdrawn';
  }

  /// Class assignment for this student in the selected session
  /// (promoted / repeated students use their current class).
  static StudentClass? _assignmentForSession(
    List<StudentClass> assignments,
    String admissionNo,
    String session,
  ) {
    final adm = admissionNo.trim().toLowerCase();
    final sess = session.trim();
    final matches = assignments
        .where(
          (a) =>
              a.admissionNo.trim().toLowerCase() == adm &&
              a.session.trim() == sess,
        )
        .toList();
    if (matches.isEmpty) return null;
    return matches.last;
  }

  static bool _classMatches(String studentClass, String filter) {
    if (filter == 'All' || filter.trim().isEmpty) return true;
    final a = _norm(studentClass);
    final b = _norm(filter);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.startsWith(b) || b.startsWith(a);
  }

  /// Snapshot of fee status for assigned students in a session/term.
  static Future<_FeeSnapshot> _snapshot({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final sess = (session ?? Sessions.current()).trim();
    final trm = (term ?? 'First Term').trim();
    final filter = classFilter ?? 'All';

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
        final sc = _assignmentForSession(
          assignments,
          student.admissionNo,
          sess,
        );
        if (sc == null) continue;
        if (_inactive(sc.className)) continue;
        if (!_classMatches(sc.className, filter)) continue;

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
      } catch (_) {}
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

  /// Money received for the selected session/term (not all-time).
  static Future<double> totalFeesCollected({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final sess = session?.trim();
    final trm = term?.trim();
    final filter = classFilter ?? 'All';

    final payments = await StudentFeePaymentStorage.getPayments();
    double total = 0;
    for (final payment in payments) {
      if (sess != null &&
          sess.isNotEmpty &&
          payment.session.trim() != sess) {
        continue;
      }
      if (trm != null &&
          trm.isNotEmpty &&
          payment.term.trim().toLowerCase() != trm.toLowerCase()) {
        continue;
      }
      if (!_classMatches(payment.className, filter)) continue;
      total += payment.amountPaid;
    }
    return total;
  }

  static Future<double> totalOutstanding({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final s = await _snapshot(
      session: session,
      term: term,
      classFilter: classFilter,
    );
    return s.outstanding;
  }

  static Future<int> totalStudentsPaid({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final s = await _snapshot(
      session: session,
      term: term,
      classFilter: classFilter,
    );
    return s.fullyPaid;
  }

  static Future<int> totalDebtors({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final s = await _snapshot(
      session: session,
      term: term,
      classFilter: classFilter,
    );
    return s.debtors;
  }

  static Future<double> collectionPercentage({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final s = await _snapshot(
      session: session,
      term: term,
      classFilter: classFilter,
    );
    if (s.expected <= 0) return 0;
    return (s.collectedForTerm / s.expected) * 100;
  }

  static Future<double> expectedTotal({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final s = await _snapshot(
      session: session,
      term: term,
      classFilter: classFilter,
    );
    return s.expected;
  }

  static Future<List<StudentFeePayment>> recentPayments() async {
    final payments = await StudentFeePaymentStorage.getPayments();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    if (payments.length <= 5) return payments;
    return payments.take(5).toList();
  }


  /// Number of payment records (optionally filtered).
  static Future<int> totalPayments({
    String? session,
    String? term,
    String? classFilter,
  }) async {
    final sess = session?.trim();
    final trm = term?.trim();
    final filter = classFilter ?? 'All';
    final payments = await StudentFeePaymentStorage.getPayments();
    int count = 0;
    for (final payment in payments) {
      if (sess != null &&
          sess.isNotEmpty &&
          payment.session.trim() != sess) {
        continue;
      }
      if (trm != null &&
          trm.isNotEmpty &&
          payment.term.trim().toLowerCase() != trm.toLowerCase()) {
        continue;
      }
      if (!_classMatches(payment.className, filter)) continue;
      count++;
    }
    return count;
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
