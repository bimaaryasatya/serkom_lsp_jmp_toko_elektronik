class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String image;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map) {
    return BannerModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      image: map['image'] ?? '',
    );
  }
}
