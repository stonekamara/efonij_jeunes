class Profile {
  const Profile({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.region,
    this.telephone,
    this.avatarUrl,
    this.pilier,
    this.niveauPasseport = 1,
    this.points = 0,
    this.matricule,
  });

  final String id;
  final String prenom;
  final String nom;
  final String email;
  final String? region;
  final String? telephone;
  final String? avatarUrl;
  final String? pilier;
  final int niveauPasseport;
  final int points;

  /// Identifiant unique lisible (FONIJ-YY-XXXXXX), généré par la base.
  final String? matricule;

  String get fullName => '$prenom $nom';

  bool get aChoisiPilier => pilier != null && pilier!.isNotEmpty;

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return (p + n).toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      prenom: (json['prenom'] as String?) ?? '',
      nom: (json['nom'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      region: json['region'] as String?,
      telephone: json['telephone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      pilier: json['pilier'] as String?,
      niveauPasseport: (json['niveau_passeport'] as num?)?.toInt() ?? 1,
      points: (json['points'] as num?)?.toInt() ?? 0,
      matricule: json['matricule'] as String?,
    );
  }
}
