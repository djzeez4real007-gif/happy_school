/// Canonical class levels for registration & promotion (no arms here).
class SchoolClassLevels {
  static const List<String> primary = [
    'Primary 1',
    'Primary 2',
    'Primary 3',
    'Primary 4',
    'Primary 5',
    'Primary 6',
  ];

  static const List<String> junior = ['JSS1', 'JSS2', 'JSS3'];
  static const List<String> senior = ['SS1', 'SS2', 'SS3'];

  /// Order used in class registration dropdown.
  static const List<String> all = [
    ...primary,
    ...junior,
    ...senior,
  ];

  /// Promotion paths: source → target (target may be Graduated).
  static const List<({String label, String source, String target, bool graduated})>
      promotionPaths = [
    (label: 'Primary 1 → Primary 2', source: 'Primary 1', target: 'Primary 2', graduated: false),
    (label: 'Primary 2 → Primary 3', source: 'Primary 2', target: 'Primary 3', graduated: false),
    (label: 'Primary 3 → Primary 4', source: 'Primary 3', target: 'Primary 4', graduated: false),
    (label: 'Primary 4 → Primary 5', source: 'Primary 4', target: 'Primary 5', graduated: false),
    (label: 'Primary 5 → Primary 6', source: 'Primary 5', target: 'Primary 6', graduated: false),
    (label: 'Primary 6 → JSS1', source: 'Primary 6', target: 'JSS1', graduated: false),
    (label: 'JSS1 → JSS2', source: 'JSS1', target: 'JSS2', graduated: false),
    (label: 'JSS2 → JSS3', source: 'JSS2', target: 'JSS3', graduated: false),
    (label: 'JSS3 → SS1', source: 'JSS3', target: 'SS1', graduated: false),
    (label: 'SS1 → SS2', source: 'SS1', target: 'SS2', graduated: false),
    (label: 'SS2 → SS3', source: 'SS2', target: 'SS3', graduated: false),
    (label: 'SS3 → Graduated', source: 'SS3', target: 'Graduated', graduated: true),
  ];
}
