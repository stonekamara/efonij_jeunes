/// Un commentaire sur une publication.
class Commentaire {
  const Commentaire({
    required this.id,
    required this.publicationId,
    required this.auteurId,
    required this.contenu,
    required this.createdAt,
    this.auteurPrenom,
    this.auteurNom,
    this.auteurAvatarUrl,
  });

  final String id;
  final String publicationId;
  final String auteurId;
  final String contenu;
  final DateTime createdAt;
  final String? auteurPrenom;
  final String? auteurNom;
  final String? auteurAvatarUrl;

  String get auteurAffichable {
    final nom = [auteurPrenom, auteurNom]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
    return nom.isEmpty ? 'Membre' : nom;
  }

  factory Commentaire.fromMap(Map<String, dynamic> map) {
    final auteur = map['profiles'];
    return Commentaire(
      id: map['id'] as String,
      publicationId: map['publication_id'] as String,
      auteurId: map['auteur_id'] as String,
      contenu: (map['contenu'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      auteurPrenom: auteur is Map ? auteur['prenom'] as String? : null,
      auteurNom: auteur is Map ? auteur['nom'] as String? : null,
      auteurAvatarUrl: auteur is Map ? auteur['avatar_url'] as String? : null,
    );
  }
}
