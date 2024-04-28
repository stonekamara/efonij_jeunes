import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client.dart';
import '../../../core/utils/labels.dart';
import '../models/cv.dart';

/// Persistance du CV : chargement, sauvegarde (upsert + remplacement des
/// sections), snapshot JSON, génération du PDF et upload vers Storage.
class CvRepository {
  /// Charge le CV courant de l'utilisateur avec toutes ses sections.
  Future<Cv?> charger(String userId) async {
    final row = await supabase
        .from('cvs')
        .select(
            '*, cv_formations(*), cv_experiences(*), cv_competences(*), cv_langues(*)')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Cv.fromMap(row);
  }

  /// Upsert du CV + remplacement complet des sections (idempotent).
  Future<void> sauvegarder(Cv cv) async {
    final userId = cv.userId;
    final row = await supabase
        .from('cvs')
        .upsert({
          'user_id': userId,
          'titre_poste': cv.titrePoste,
          'resume': cv.resume,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id')
        .select('id')
        .single();
    final cvId = row['id'] as String;

    await supabase.from('cv_formations').delete().eq('cv_id', cvId);
    if (cv.formations.isNotEmpty) {
      await supabase.from('cv_formations').insert([
        for (final f in cv.formations)
          {'cv_id': cvId, 'diplome': f.diplome, 'etablissement': f.etablissement, 'annee_debut': f.anneeDebut, 'annee_fin': f.anneeFin}
      ]);
    }

    await supabase.from('cv_experiences').delete().eq('cv_id', cvId);
    if (cv.experiences.isNotEmpty) {
      await supabase.from('cv_experiences').insert([
        for (final e in cv.experiences)
          {'cv_id': cvId, 'poste': e.poste, 'organisation': e.organisation, 'date_debut': e.dateDebut?.toIso8601String().split('T').first, 'date_fin': e.dateFin?.toIso8601String().split('T').first, 'description': e.description}
      ]);
    }

    await supabase.from('cv_competences').delete().eq('cv_id', cvId);
    if (cv.competences.isNotEmpty) {
      await supabase.from('cv_competences').insert([
        for (final c in cv.competences)
          {'cv_id': cvId, 'nom': c.nom}
      ]);
    }

    await supabase.from('cv_langues').delete().eq('cv_id', cvId);
    if (cv.langues.isNotEmpty) {
      await supabase.from('cv_langues').insert([
        for (final l in cv.langues)
          {'cv_id': cvId, 'langue': l.langue, 'niveau': l.niveau}
      ]);
    }
  }

  /// Snapshot JSON du CV envoyé avec la candidature (lisible par le back-office).
  Map<String, dynamic> snapshot(
    Cv cv, {
    required String nomComplet,
    String? email,
    String? telephone,
    String? region,
    String? matricule,
    int? niveauPasseport,
  }) =>
      {
        'nom_complet': nomComplet,
        'email': email,
        'telephone': telephone,
        'region': region,
        'matricule': matricule,
        'niveau_passeport': niveauPasseport,
        'titre_poste': cv.titrePoste,
        'resume': cv.resume,
        'formations': [
          for (final f in cv.formations)
            {
              'diplome': f.diplome,
              'etablissement': f.etablissement,
              'annee_debut': f.anneeDebut,
              'annee_fin': f.anneeFin,
            }
        ],
        'experiences': [
          for (final e in cv.experiences)
            {
              'poste': e.poste,
              'organisation': e.organisation,
              'date_debut': e.dateDebut?.toIso8601String().split('T').first,
              'date_fin': e.dateFin?.toIso8601String().split('T').first,
              'description': e.description,
            }
        ],
        'competences': [for (final c in cv.competences) c.nom],
        'langues': [
          for (final l in cv.langues) {'langue': l.langue, 'niveau': l.niveau}
        ],
      };

  /// Génère le PDF du CV (mise en page simple, sections dans l'ordre).
  Future<Uint8List> genererPdf(
    Cv cv, {
    required String nomComplet,
    String? email,
    String? telephone,
    String? region,
    String? matricule,
  }) async {
    final doc = pw.Document();

    pw.Widget sectionTitle(String title) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
              letterSpacing: 1,
            ),
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            nomComplet,
            style: const pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          if (cv.titrePoste != null && cv.titrePoste!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                cv.titrePoste!,
                style: pw.TextStyle(
                  fontSize: 13,
                  color: PdfColors.teal700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (matricule != null && matricule.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                matricule,
                style: const pw.TextStyle(
                  fontSize: 10.5,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          if (email != null || telephone != null || region != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                [email, telephone, region].whereType<String>().join('  ·  '),
                style: const pw.TextStyle(
                  fontSize: 10.5,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          if (cv.resume != null && cv.resume!.isNotEmpty) ...[
            sectionTitle('Résumé'),
            pw.Text(cv.resume!, style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 1.3)),
          ],
          if (cv.formations.isNotEmpty) ...[
            sectionTitle('Formations'),
            for (final f in cv.formations)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(f.diplome, style: const pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                          if (f.etablissement != null && f.etablissement!.isNotEmpty)
                            pw.Text(f.etablissement!, style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    if (f.anneeDebut != null || f.anneeFin != null)
                      pw.Text(
                        '${f.anneeDebut ?? '—'} - ${f.anneeFin ?? 'auj.'}',
                        style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey600),
                      ),
                  ],
                ),
              ),
          ],
          if (cv.experiences.isNotEmpty) ...[
            sectionTitle('Expériences'),
            for (final e in cv.experiences)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(e.poste, style: const pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                    if (e.organisation != null && e.organisation!.isNotEmpty)
                      pw.Text(e.organisation!, style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700)),
                    if (e.description != null && e.description!.isNotEmpty)
                      pw.Text(e.description!, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.2)),
                  ],
                ),
              ),
          ],
          if (cv.competences.isNotEmpty) ...[
            sectionTitle('Compétences'),
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final c in cv.competences)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(c.nom, style: const pw.TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ],
          if (cv.langues.isNotEmpty) ...[
            sectionTitle('Langues'),
            for (final l in cv.langues)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  '${l.langue} — ${niveauLabel(l.niveau)}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  /// Upload du PDF dans le bucket « cvs », dossier de l'utilisateur.
  Future<String> uploadPdf(Uint8List bytes, {
    required String userId,
    required String candidatureId,
  }) async {
    final path = '$userId/$candidatureId.pdf';
    await supabase.storage.from('cvs').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    return supabase.storage.from('cvs').getPublicUrl(path);
  }
}
