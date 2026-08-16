import '../services/student_storage.dart';
import '../services/teacher_storage.dart';
import '../services/class_storage.dart';
import '../services/subject_storage.dart';
import '../services/student_fee_payment_storage.dart';

class DashboardService {
  static Future<int> totalStudents() async {
    final students = await StudentStorage.getStudents();
    return students.length;
  }

  static Future<int> totalTeachers() async {
    final teachers = await TeacherStorage.getTeachers();
    return teachers.length;
  }

  static Future<int> totalClasses() async {
    final classes = await ClassStorage.getClasses();
    return classes.length;
  }

  static Future<int> totalSubjects() async {
    final subjects = await SubjectStorage.getSubjects();
    return subjects.length;
  }

  static Future<double> totalFeesCollected() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    double total = 0;

    for (final payment in payments) {
      total += payment.amountPaid;
    }

    return total;
  }

  static Future<double> totalOutstanding() async {
    final payments = await StudentFeePaymentStorage.getPayments();

    double total = 0;

    for (final payment in payments) {
      total += payment.balance;
    }

    return total;
  }
}
