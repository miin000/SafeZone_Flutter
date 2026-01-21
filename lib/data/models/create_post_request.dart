class CreatePostRequest {
  final String content;
  final List<String> imageUrls;
  final String? location;
  final String? diseaseType;
  final String source;

  const CreatePostRequest({
    required this.content,
    this.imageUrls = const [],
    this.location,
    this.diseaseType,
    this.source = 'citizen',
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'imageUrls': imageUrls,
      if (location != null) 'location': location,
      if (diseaseType != null) 'diseaseType': diseaseType,
      'source': source,
    };
  }
}

class CreateReportRequest {
  final String diseaseType;
  final String description;
  final double lat;
  final double lon;
  final String? address;
  final List<String>? symptoms;
  final int? affectedCount;

  CreateReportRequest({
    required this.diseaseType,
    required this.description,
    required this.lat,
    required this.lon,
    this.address,
    this.symptoms,
    this.affectedCount,
  });

  Map<String, dynamic> toJson() => {
    'diseaseType': diseaseType,
    'description': description,
    'lat': lat,
    'lon': lon,
    'address': address,
    'symptoms': symptoms,
    'affectedCount': affectedCount,
  };
}
