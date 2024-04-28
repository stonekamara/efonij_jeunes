/// Une communauté thématique.
class Communaute {
  const Communaute({
    required this.id,
    required this.nom,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.pilier,
    required this.createdAt,
  });

  final String id;
  final String nom;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String? pilier;
  final DateTime createdAt;

  factory Communaute.fromMap(Map<String, dynamic> map) {
    return Communaute(
      id: map['id'] as String,
      nom: (map['nom'] as String?) ?? '',
      slug: (map['slug'] as String?) ?? '',
      description: map['description'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      pilier: map['pilier'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
