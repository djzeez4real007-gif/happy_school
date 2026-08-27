class WelcomeSlide {
  final String id;
  final String imageUrl;
  /// Hive key in welcome_images box (preferred for picked photos).
  final String imageKey;
  final String caption;
  final String subtitle;

  WelcomeSlide({
    required this.id,
    this.imageUrl = '',
    this.imageKey = '',
    required this.caption,
    required this.subtitle,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imageUrl': imageUrl,
        'imageKey': imageKey,
        'caption': caption,
        'subtitle': subtitle,
      };

  factory WelcomeSlide.fromMap(Map map) => WelcomeSlide(
        id: map['id']?.toString() ?? '',
        imageUrl: map['imageUrl']?.toString() ?? '',
        imageKey: map['imageKey']?.toString() ?? '',
        caption: map['caption']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
      );
}
