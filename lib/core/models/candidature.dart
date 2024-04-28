import 'offre.dart';
import 'validation.dart';

/// Une candidature du jeune à une offre.
class Candidature {
  const Candidature({
    required this.id,
    required this.offreId,
    required this.userId,
    this.statut = 'en_attente',
    required this.createdAt,
    this.offre,
    this.validations = const [],
    this.cvPdfUrl,
    this.cvSnapshot,
    this.reviewedAt,
  });

  final String id;
  final String offreId;
  final String userId;
  final String statut; // en_attente | acceptee | refusee
  final DateTime createdAt;
  final Offre? offre;

  /// Validations enregistrées par les organisations partenaires (scan QR).
  final List<Validation> validations;

  /// CV envoyé avec la candidature (PDF + snapshot JSON).
  final String? cvPdfUrl;
  final Map<String, dynamic>? cvSnapshot;
  final DateTime? reviewedAt;

  factory Candidature.fromMap(Map<String, dynamic> map) {
    final offreMap = map['offres'];
    final validationsRaw = map['validations'];
    return Candidature(
      id: map['id'] as String,
      offreId: map['offre_id'] as String,
      userId: map['user_id'] as String,
      statut: (map['statut'] as String?) ?? 'en_attente',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      offre: offreMap is Map<String, dynamic>
          ? Offre.fromMap(offreMap)
          : null,
      validations: validationsRaw is List
          ? validationsRaw
              .whereType<Map<String, dynamic>>()
              .map(Validation.fromMap)
              .toList()
          : const [],
      cvPdfUrl: map['cv_pdf_url'] as String?,
      cvSnapshot: map['cv_snapshot'] is Map
          ? Map<String, dynamic>.from(map['cv_snapshot'] as Map)
          : null,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'] as String)
          : null,
    );
  }
}
