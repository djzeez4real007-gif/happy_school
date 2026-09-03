class PricingPackage {
  final String id;
  final String name;
  final String priceLabel;
  final String period;
  final List<String> features;
  final bool highlighted;

  const PricingPackage({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.period,
    required this.features,
    this.highlighted = false,
  });

  PricingPackage copyWith({
    String? name,
    String? priceLabel,
    String? period,
    List<String>? features,
    bool? highlighted,
  }) {
    return PricingPackage(
      id: id,
      name: name ?? this.name,
      priceLabel: priceLabel ?? this.priceLabel,
      period: period ?? this.period,
      features: features ?? this.features,
      highlighted: highlighted ?? this.highlighted,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'priceLabel': priceLabel,
        'period': period,
        'features': features,
        'highlighted': highlighted,
      };

  factory PricingPackage.fromMap(Map map) {
    final feats = map['features'];
    return PricingPackage(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      priceLabel: (map['priceLabel'] ?? '').toString(),
      period: (map['period'] ?? '').toString(),
      features: feats is List
          ? feats.map((e) => e.toString()).toList()
          : <String>[],
      highlighted: map['highlighted'] == true,
    );
  }

  static List<PricingPackage> get defaults => const [
        PricingPackage(
          id: 'starter',
          name: 'Starter',
          priceLabel: '₦25,000',
          period: 'per term',
          features: [
            'Up to 150 students',
            'Results, attendance & fees',
            'Report cards & receipts',
            'Email support',
          ],
        ),
        PricingPackage(
          id: 'standard',
          name: 'Standard',
          priceLabel: '₦45,000',
          period: 'per term',
          highlighted: true,
          features: [
            'Up to 400 students',
            'All Starter features',
            'Promotion & transcripts',
            'Training + priority support',
          ],
        ),
        PricingPackage(
          id: 'premium',
          name: 'Premium',
          priceLabel: '₦80,000',
          period: 'per term',
          features: [
            'High student capacity',
            'All modules unlocked',
            'Multi-user roles',
            'WhatsApp support',
          ],
        ),
        PricingPackage(
          id: 'lifetime',
          name: 'Lifetime',
          priceLabel: '₦400,000',
          period: 'one-time',
          features: [
            'Current major version',
            '1 year of updates',
            'Optional yearly maintenance',
            'Best for long-term ownership',
          ],
        ),
      ];
}
