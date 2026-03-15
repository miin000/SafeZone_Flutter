class Post {
  final String id;
  final String content;
  final List<String> imageUrls;
  final String? location;
  final String? diseaseType;
  final String source;
  final DateTime createdAt;
  final String authorName;

  const Post({
    required this.id,
    required this.content,
    required this.imageUrls,
    this.location,
    this.diseaseType,
    required this.source,
    required this.createdAt,
    required this.authorName,
  });
}
