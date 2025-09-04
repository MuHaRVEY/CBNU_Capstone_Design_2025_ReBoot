class AdModel {
  final String imageUrl;
  final String link;
  final DateTime expiresAt;

  AdModel({
    required this.imageUrl,
    required this.link,
    required this.expiresAt,
  });

  factory AdModel.fromMap(Map<dynamic, dynamic> map) {
    return AdModel(
      imageUrl: map['imageUrl'] ?? '',
      link: map['link'] ?? '',
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now(),
    );
  }
}
