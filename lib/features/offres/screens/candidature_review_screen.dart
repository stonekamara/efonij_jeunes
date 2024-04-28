import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/offre.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/labels.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/badges.dart';
import '../../candidatures/providers/candidatures_provider.dart';
import '../../cv/models/cv.dart';
import '../../cv/providers/cv_provider.dart';
import '../../profil/models/profile.dart';
import '../../profil/providers/profil_provider.dart';
import '../providers/offre_detail_providers.dart';

/// UUID v4 côté client (id de candidature connu avant l'insertion, pour
/// nommer le PDF avant l'envoi).
String _uuidV4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Soumet la candidature : snapshot JSON + PDF + upload + insertion.
/// Retourne `true` si la candidature a bien été envoyée.
Future<bool> soumettreCandidature(
  BuildContext context,
  WidgetRef ref,
  Offre offre,
) async {
  try {
    final user = supabase.auth.currentUser!;

    // 1. CV obligatoire (résumé ou formation).
    final cv = await ref.read(cvProvider.future);
    if (cv == null || cv.estVide) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complète ton CV avant de postuler.')),
        );
      }
      return false;
    }

    final repo = ref.read(cvRepositoryProvider);
    final profile = await ref.read(profilProvider.future);

    // 2. Snapshot JSON + PDF + upload (nommés par l'id de candidature).
    final candidatureId = _uuidV4();
    final snapshot = repo.snapshot(
      cv,
      nomComplet: profile.fullName,
      email: profile.email,
      telephone: profile.telephone,
      region: profile.region,
      matricule: profile.matricule,
      niveauPasseport: profile.niveauPasseport,
    );
    final pdfBytes = await repo.genererPdf(
      cv,
      nomComplet: profile.fullName,
      email: profile.email,
      telephone: profile.telephone,
      region: profile.region,
      matricule: profile.matricule,
    );
    final pdfUrl = await repo.uploadPdf(
      pdfBytes,
      userId: user.id,
      candidatureId: candidatureId,
    );

    // 3. Insertion unique avec snapshot + PDF déjà renseignés.
    await supabase.from('candidatures').insert({
      'id': candidatureId,
      'offre_id': offre.id,
      'user_id': user.id,
      'cv_snapshot': snapshot,
      'cv_pdf_url': pdfUrl,
    });

    ref.invalidate(candidatureForOffreProvider(offre.id));
    ref.invalidate(candidaturesProvider);
    // +10 pts attribués par le trigger SQL : on recharge le profil pour que
    // la carte affiche les nouveaux points immédiatement.
    ref.invalidate(profilProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidature envoyée ! +10 points 🍀')),
      );
    }
    return true;
  } on PostgrestException catch (e) {
    if (e.code == '23505') {
      ref.invalidate(candidatureForOffreProvider(offre.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà postulé à cette offre.'),
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.message}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue. Réessayez.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    return false;
  }
}

/// Écran de relecture avant envoi de la candidature : l'offre choisie,
/// un aperçu du CV qui sera joint, et le choix « Modifier » / « Confirmer ».
class CandidatureReviewScreen extends ConsumerStatefulWidget {
  const CandidatureReviewScreen({super.key, required this.offreId});

  final String offreId;

  @override
  ConsumerState<CandidatureReviewScreen> createState() =>
      _CandidatureReviewScreenState();
}

class _CandidatureReviewScreenState extends ConsumerState<CandidatureReviewScreen> {
  bool _submitting = false;

  Future<void> _submit(Offre offre) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await soumettreCandidature(context, ref, offre);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offreAsync = ref.watch(offreDetailProvider(widget.offreId));
    final cvAsync = ref.watch(cvProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmer ma candidature')),
      body: AsyncView<Offre>(
        value: offreAsync,
        onRetry: () => ref.invalidate(offreDetailProvider(widget.offreId)),
        builder: (context, offre) {
          final cvValide = cvAsync.value != null && !cvAsync.value!.estVide;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _OffreSummary(offre: offre),
                    const SizedBox(height: 16),
                    _CvSection(
                      cvAsync: cvAsync,
                      onGoToCv: () => context.push('/cv'),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            offre.estOuverte && cvValide && !_submitting
                                ? () => _submit(offre)
                                : null,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _submitting ? 'Envoi…' : 'Confirmer et envoyer',
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => context.push('/cv'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Modifier mon CV'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Encart récapitulatif de l'offre choisie.
class _OffreSummary extends StatelessWidget {
  const _OffreSummary({required this.offre});

  final Offre offre;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.10),
              Colors.white,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous postulez à',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        offre.titre,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TypeBadge(type: offre.type),
                if (offre.pilier != null) PilierBadge(code: offre.pilier),
                if (offre.structureNom != null)
                  _SoftChip(
                    icon: Icons.apartment,
                    label: offre.structureNom!,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Date limite : ${formatDate(offre.dateLimite)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aperçu du CV qui sera joint à la candidature.
class _CvSection extends StatelessWidget {
  const _CvSection({required this.cvAsync, required this.onGoToCv});

  final AsyncValue<Cv?> cvAsync;
  final VoidCallback onGoToCv;

  @override
  Widget build(BuildContext context) {
    return cvAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Impossible de charger ton CV.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onGoToCv,
                child: const Text('Créer mon CV'),
              ),
            ],
          ),
        ),
      ),
      data: (cv) {
        if (cv == null || cv.estVide) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ton CV est vide : complète-le avant de postuler.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onGoToCv,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Créer mon CV'),
                  ),
                ],
              ),
            ),
          );
        }
        return _CvPreviewCard(cv: cv);
      },
    );
  }
}

/// Carte de prévisualisation complète du CV (lecture seule).
class _CvPreviewCard extends ConsumerWidget {
  const _CvPreviewCard({required this.cv});

  final Cv cv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profilProvider);

    return profileAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: const [
              Icon(Icons.error_outline, color: AppColors.danger),
              SizedBox(height: 8),
              Text(
                'Impossible de charger ton profil.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        final completion = _completion(cv);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              icon: Icons.description_outlined,
              label: 'CV qui sera envoyé',
              trailing: '$completion% complet',
            ),
            const SizedBox(height: 8),
            if (completion < 100) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CvContent(cv: cv, profile: profile),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ce CV est joint automatiquement à ta candidature. '
                    'Tu peux le modifier à tout moment, même après l\'envoi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Corps du CV : identité + contact + sections.
class _CvContent extends StatelessWidget {
  const _CvContent({required this.cv, required this.profile});

  final Cv cv;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identité.
        Row(
          children: [
            AvatarView(
              url: profile.avatarUrl,
              prenom: profile.prenom,
              nom: profile.nom,
              size: 52,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (profile.matricule != null) profile.matricule!,
                      'Niveau ${profile.niveauPasseport}',
                      if (profile.pilier != null) 'Pilier ${profile.pilier}',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Coordonnées.
        if (profile.email.isNotEmpty ||
            (profile.telephone?.isNotEmpty ?? false) ||
            (profile.region?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (profile.email.isNotEmpty)
                _ContactChip(icon: Icons.mail_outline, text: profile.email),
              if (profile.telephone?.isNotEmpty ?? false)
                _ContactChip(icon: Icons.phone_outlined, text: profile.telephone!),
              if (profile.region?.isNotEmpty ?? false)
                _ContactChip(icon: Icons.place_outlined, text: profile.region!),
            ],
          ),
        ],
        const Divider(height: 24),
        // Titre poste.
        if (cv.titrePoste != null && cv.titrePoste!.isNotEmpty) ...[
          Text(
            cv.titrePoste!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        // Résumé.
        if (cv.resume != null && cv.resume!.isNotEmpty) ...[
          Text(
            cv.resume!,
            style: const TextStyle(fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 14),
        ],
        // Formations.
        _CvSectionBlock(
          icon: Icons.school_outlined,
          title: 'Formations',
          child: cv.formations.isEmpty
              ? const _EmptySectionHint()
              : Column(
                  children: [
                    for (final f in cv.formations)
                      _TwoLineTile(
                        title: f.diplome,
                        subtitle: [
                          if (f.etablissement != null &&
                              f.etablissement!.isNotEmpty)
                            f.etablissement!,
                          if (f.anneeDebut != null || f.anneeFin != null)
                            '${f.anneeDebut ?? '—'} - ${f.anneeFin ?? 'auj.'}',
                        ].join(' · '),
                      ),
                  ],
                ),
        ),
        // Expériences.
        _CvSectionBlock(
          icon: Icons.work_outline,
          title: 'Expériences',
          child: cv.experiences.isEmpty
              ? const _EmptySectionHint()
              : Column(
                  children: [
                    for (final e in cv.experiences)
                      _TwoLineTile(
                        title: e.poste,
                        subtitle: [
                          if (e.organisation != null &&
                              e.organisation!.isNotEmpty)
                            e.organisation!,
                        ].join(' · '),
                        description: e.description,
                      ),
                  ],
                ),
        ),
        // Compétences.
        _CvSectionBlock(
          icon: Icons.build_outlined,
          title: 'Compétences',
          child: cv.competences.isEmpty
              ? const _EmptySectionHint()
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in cv.competences)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.nom,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        // Langues.
        _CvSectionBlock(
          icon: Icons.language,
          title: 'Langues',
          child: cv.langues.isEmpty
              ? const _EmptySectionHint()
              : Column(
                  children: [
                    for (final l in cv.langues)
                      _TwoLineTile(
                        title: l.langue,
                        subtitle: niveauLabel(l.niveau),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CvSectionBlock extends StatelessWidget {
  const _CvSectionBlock({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TwoLineTile extends StatelessWidget {
  const _TwoLineTile({required this.title, required this.subtitle, this.description});

  final String title;
  final String subtitle;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          if (description != null && description!.isNotEmpty)
            Text(
              description!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '—',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
      ],
    );
  }
}

/// Taux de complétude du CV (sur 6 sections).
int _completion(Cv cv) {
  var filled = 0;
  if (cv.titrePoste?.isNotEmpty ?? false) filled++;
  if (cv.resume?.isNotEmpty ?? false) filled++;
  if (cv.formations.isNotEmpty) filled++;
  if (cv.experiences.isNotEmpty) filled++;
  if (cv.competences.isNotEmpty) filled++;
  if (cv.langues.isNotEmpty) filled++;
  return (filled / 6 * 100).round();
}
