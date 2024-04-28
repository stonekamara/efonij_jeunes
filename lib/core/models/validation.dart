/// Une validation de candidature enregistrée par une organisation partenaire
/// après le scan du QR code du Passeport Jeune.
class Validation {
  const Validation({
    required this.id,
    required this.candidatureId,
    required this.type,
    required this.scannedAt,
    this.notes,
  });

  final String id;
  final String candidatureId;

  /// presence_evenement | confirmation_candidature
  final String type;
  final DateTime scannedAt;
  final String? notes;

  bool get estPresence => type == 'presence_evenement';
  bool get estConfirmation => type == 'confirmation_candidature';

  String get libelle =>
      estPresence ? 'Présence validée' : 'Candidature confirmée';

  factory Validation.fromMap(Map<String, dynamic> map) {
    return Validation(
      id: map['id'] as String,
      candidatureId: (map['candidature_id'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'confirmation_candidature',
      scannedAt: DateTime.tryParse((map['scanned_at'] as String?) ?? '') ??
          DateTime.now(),
      notes: map['notes'] as String?,
    );
  }
}
