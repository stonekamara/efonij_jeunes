/// Une formation du CV.
class CvFormation {
  const CvFormation({
    this.id,
    required this.diplome,
    this.etablissement,
    this.anneeDebut,
    this.anneeFin,
  });

  final String? id;
  final String diplome;
  final String? etablissement;
  final int? anneeDebut;
  final int? anneeFin;

  Map<String, dynamic> toMap() => {
        'id': id,
        'diplome': diplome,
        'etablissement': etablissement,
        'annee_debut': anneeDebut,
        'annee_fin': anneeFin,
      };

  factory CvFormation.fromMap(Map<String, dynamic> map) => CvFormation(
        id: map['id'] as String?,
        diplome: (map['diplome'] as String?) ?? '',
        etablissement: map['etablissement'] as String?,
        anneeDebut: (map['annee_debut'] as num?)?.toInt(),
        anneeFin: (map['annee_fin'] as num?)?.toInt(),
      );
}

/// Une expérience du CV.
class CvExperience {
  const CvExperience({
    this.id,
    required this.poste,
    this.organisation,
    this.dateDebut,
    this.dateFin,
    this.description,
  });

  final String? id;
  final String poste;
  final String? organisation;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? description;

  Map<String, dynamic> toMap() => {
        'id': id,
        'poste': poste,
        'organisation': organisation,
        'date_debut': dateDebut?.toIso8601String().split('T').first,
        'date_fin': dateFin?.toIso8601String().split('T').first,
        'description': description,
      };

  factory CvExperience.fromMap(Map<String, dynamic> map) => CvExperience(
        id: map['id'] as String?,
        poste: (map['poste'] as String?) ?? '',
        organisation: map['organisation'] as String?,
        dateDebut:
            map['date_debut'] != null ? DateTime.tryParse(map['date_debut'] as String) : null,
        dateFin:
            map['date_fin'] != null ? DateTime.tryParse(map['date_fin'] as String) : null,
        description: map['description'] as String?,
      );
}

/// Une compétence du CV.
class CvCompetence {
  const CvCompetence({this.id, required this.nom});

  final String? id;
  final String nom;

  Map<String, dynamic> toMap() => {'id': id, 'nom': nom};

  factory CvCompetence.fromMap(Map<String, dynamic> map) =>
      CvCompetence(id: map['id'] as String?, nom: (map['nom'] as String?) ?? '');
}

/// Une langue du CV.
class CvLangue {
  const CvLangue({this.id, required this.langue, this.niveau});

  final String? id;
  final String langue;
  final String? niveau; // debutant | intermediaire | courant | bilingue

  Map<String, dynamic> toMap() => {'id': id, 'langue': langue, 'niveau': niveau};

  factory CvLangue.fromMap(Map<String, dynamic> map) => CvLangue(
        id: map['id'] as String?,
        langue: (map['langue'] as String?) ?? '',
        niveau: map['niveau'] as String?,
      );
}

/// CV courant d'un jeune (titre + résumé + sections).
class Cv {
  const Cv({
    this.id,
    required this.userId,
    this.titrePoste,
    this.resume,
    this.formations = const [],
    this.experiences = const [],
    this.competences = const [],
    this.langues = const [],
  });

  final String? id;
  final String userId;
  final String? titrePoste;
  final String? resume;
  final List<CvFormation> formations;
  final List<CvExperience> experiences;
  final List<CvCompetence> competences;
  final List<CvLangue> langues;

  /// Un CV « vide » n'a ni résumé ni formation : le jeune ne peut pas postuler.
  bool get estVide =>
      (resume == null || resume!.trim().isEmpty) && formations.isEmpty;

  factory Cv.fromMap(Map<String, dynamic> map) => Cv(
        id: map['id'] as String?,
        userId: map['user_id'] as String,
        titrePoste: map['titre_poste'] as String?,
        resume: map['resume'] as String?,
        formations: ((map['cv_formations'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CvFormation.fromMap)
            .toList(),
        experiences: ((map['cv_experiences'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CvExperience.fromMap)
            .toList(),
        competences: ((map['cv_competences'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CvCompetence.fromMap)
            .toList(),
        langues: ((map['cv_langues'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CvLangue.fromMap)
            .toList(),
      );
}
