class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.title,
    required this.photographer,
    required this.pageUrl,
    required this.imageUrl,
    required this.originalUrl,
    required this.width,
    required this.height,
    this.averageColor = '#252333',
  });

  final int id;
  final String title;
  final String photographer;
  final String pageUrl;
  final String imageUrl;
  final String originalUrl;
  final int width;
  final int height;
  final String averageColor;

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    final source = json['src'];
    if (json['id'] is! int ||
        json['width'] is! int ||
        json['height'] is! int ||
        source is! Map<String, dynamic>) {
      throw const FormatException('Invalid wallpaper data.');
    }
    String text(Map<String, dynamic> map, String key) {
      final value = map[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Missing wallpaper field: $key.');
      }
      return value;
    }

    String url(Map<String, dynamic> map, String key) {
      final value = text(map, key);
      final uri = Uri.tryParse(value);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw FormatException('Invalid wallpaper URL: $key.');
      }
      return value;
    }

    final alt = json['alt'];
    final color = json['avg_color'];
    return Wallpaper(
      id: json['id'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      title: alt is String && alt.trim().isNotEmpty ? alt : 'A new perspective',
      photographer: text(json, 'photographer'),
      pageUrl: url(json, 'url'),
      imageUrl: url(source, 'portrait'),
      originalUrl: url(source, 'original'),
      averageColor:
          color is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)
          ? color
          : '#252333',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alt': title,
    'photographer': photographer,
    'url': pageUrl,
    'width': width,
    'height': height,
    'avg_color': averageColor,
    'src': {'portrait': imageUrl, 'original': originalUrl},
  };
}
