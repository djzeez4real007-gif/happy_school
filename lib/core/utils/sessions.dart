/// Academic sessions from a start year through well beyond 2040.
class Sessions {
  Sessions._();

  /// e.g. 2020/2021 ... 2050/2051
  static List<String> list({int fromYear = 2020, int toYear = 2050}) {
    final out = <String>[];
    for (int y = fromYear; y <= toYear; y++) {
      out.add('$y/${y + 1}');
    }
    return out;
  }

  static String current() {
    final now = DateTime.now();
    // Nigerian school year often starts around Sept
    final start = now.month >= 9 ? now.year : now.year - 1;
    return '$start/${start + 1}';
  }

  static const List<String> terms = [
    'First Term',
    'Second Term',
    'Third Term',
  ];
}
