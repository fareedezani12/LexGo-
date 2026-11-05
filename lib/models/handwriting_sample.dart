class HandwritingSample {
  final String id;
  final String title;
  final DateTime createdAt;
  final String imagePath;
  final String? recognizedText;

  const HandwritingSample({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.imagePath,
    this.recognizedText,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
    'recognized_text': recognizedText,
  };

  factory HandwritingSample.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    final imagePathValue = json['image_path'] ?? json['imagePath'];
    final recognizedTextValue = json['recognized_text'] ?? json['recognizedText'];

    return HandwritingSample(
      id: json['id'].toString(),
      title: json['title'] as String,
      createdAt: DateTime.parse(createdAtValue as String).toLocal(),
      imagePath: imagePathValue as String,
      recognizedText: recognizedTextValue as String?,
    );
  }
}
