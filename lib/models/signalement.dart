class Signalement {
  final String id;
  final String description;
  final String localisation;
  final String status;
  final String? imageUrl;
  final bool isModified;
  final String categorie;
  final DateTime? createdAt;

  Signalement({
    required this.id,
    required this.description,
    required this.localisation,
    required this.status,
    required this.imageUrl,
    required this.isModified,
    required this.categorie,
    required this.createdAt,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    final loc = json['localisation'];
    final localisationStr = loc != null
        ? '${loc['latitude']}, ${loc['longitude']}'
        : 'Non définie';

    DateTime? parsedDate;
    final dateStr = json['date_creation'];
    if (dateStr != null) {
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (e) {
        parsedDate = null;
      }
    }

    return Signalement(
      id: json['id'].toString(),
      description: json['description'] ?? '',
      localisation: localisationStr,
      status: json['status'] ?? '',
      imageUrl: json['image_base64'] ?? '',
      isModified: json['is_modified'] ?? false,
      categorie: json['categorie'] ?? 'Inconnue',
      createdAt: parsedDate,
    );
  }
}
