enum InstitutionalPublicationType { achievement, event, album }

class InstitutionalPublication {
  const InstitutionalPublication({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    this.description,
    this.imageUrl,
  });

  final String id;
  final InstitutionalPublicationType type;
  final String category;
  final String title;
  final String? description;
  final String? imageUrl;
}
