/// Une offre publiée par une structure partenaire.
class Offre {
  const Offre({
    required this.id,
    required this.titre,
    required this.type,
    this.description,
    this.prerequis,
    this.publicCible,
    this.lieu,
    this.imageUrl,
    this.pilier,
    this.structureId,
    this.dateLimite,
    this.statut = 'ouverte',
    required this.createdAt,
    this.structureNom,
  });

  final String id;
  final String titre;
  final String type; // formation | stage | emploi | concours | bootcamp
  final String? description;
  final String? prerequis;
  final String? publicCible;
  final String? lieu;
  final String? imageUrl;
  final String? pilier;
  final String? structureId;
  final DateTime? dateLimite;
  final String statut; // ouverte | fermee
  final DateTime createdAt;
  final String? structureNom;

  bool get estOuverte => statut == 'ouverte';

  factory Offre.fromMap(Map<String, dynamic> map) {
    final structure = map['organisations'];
    return Offre(
      id: map['id'] as String,
      titre: (map['titre'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'formation',
      description: map['description'] as String?,
      prerequis: map['prerequis'] as String?,
      publicCible: map['public_cible'] as String?,
      lieu: map['lieu'] as String?,
      imageUrl: map['image_url'] as String?,
      pilier: map['pilier'] as String?,
      structureId: map['structure_id'] as String?,
      dateLimite: map['date_limite'] != null
          ? DateTime.tryParse(map['date_limite'] as String)
          : null,
      statut: (map['statut'] as String?) ?? 'ouverte',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      structureNom: structure is Map
          ? structure['nom'] as String?
          : null,
    );
  }
}
