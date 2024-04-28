/// Une publication dans le fil d'une communauté.
class Publication {
  const Publication({
    required this.id,
    required this.communauteId,
    required this.auteurId,
    required this.contenu,
    this.imageUrl,
    required this.createdAt,
    this.auteurPrenom,
    this.auteurNom,
    this.auteurAvatarUrl,
    this.auteurOrganisationNom,
    this.estStructure = false,
    this.likesCount = 0,
    this.commentairesCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String communauteId;
  final String auteurId;
  final String contenu;
  final String? imageUrl;
  final DateTime createdAt;
  final String? auteurPrenom;
  final String? auteurNom;
  final String? auteurAvatarUrl;

  /// Nom de l'organisation quand l'auteur est une structure (back-office).
  final String? auteurOrganisationNom;

  /// Vrai quand l'auteur est un compte de structure (badge vérifié).
  final bool estStructure;

  final int likesCount;
  final int commentairesCount;
  final bool likedByMe;

  String get auteurAffichable {
    if (estStructure && (auteurOrganisationNom?.isNotEmpty ?? false)) {
      return auteurOrganisationNom!;
    }
    final nom = [auteurPrenom, auteurNom]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
    return nom.isEmpty ? 'Membre' : nom;
  }

  factory Publication.fromMap(Map<String, dynamic> map) {
    return Publication(
      id: map['id'] as String,
      communauteId: map['communaute_id'] as String,
      auteurId: map['auteur_id'] as String,
      contenu: (map['contenu'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      auteurPrenom: map['auteur_prenom'] as String?,
      auteurNom: map['auteur_nom'] as String?,
      auteurAvatarUrl: map['auteur_avatar_url'] as String?,
      auteurOrganisationNom: map['auteur_org_nom'] as String?,
      estStructure: (map['auteur_est_organisation'] as bool?) ?? false,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      commentairesCount: (map['commentaires_count'] as num?)?.toInt() ?? 0,
      likedByMe: (map['liked_by_me'] as bool?) ?? false,
    );
  }
}
