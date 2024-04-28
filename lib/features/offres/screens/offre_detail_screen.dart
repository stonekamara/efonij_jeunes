import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/candidature.dart';
import '../../../core/models/offre.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/badges.dart';
import '../../cv/models/cv.dart';
import '../../cv/providers/cv_provider.dart';
import '../providers/offre_detail_providers.dart';

class OffreDetailScreen extends ConsumerWidget {
  const OffreDetailScreen({super.key, required this.offreId});

  final String offreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offreAsync = ref.watch(offreDetailProvider(offreId));
    final candidatureAsync = ref.watch(candidatureForOffreProvider(offreId));
    final cvAsync = ref.watch(cvProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Détail de l'offre")),
      body: AsyncView<Offre>(
        value: offreAsync,
        onRetry: () => ref.invalidate(offreDetailProvider(offreId)),
        builder: (context, offre) {
          return _DetailBody(
            offre: offre,
            candidature: candidatureAsync.value,
            cv: cvAsync.value,
            onPostuler: () => _postuler(context, offre),
            onGoToCv: () => context.push('/cv'),
          );
        },
      ),
    );
  }

  /// Ouvre l'écran de relecture : l'utilisateur vérifie (et peut modifier)
  /// son CV avant l'envoi effectif de la candidature.
  void _postuler(BuildContext context, Offre offre) {
    context.push('/offres/${offre.id}/postuler');
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.offre,
    required this.candidature,
    required this.cv,
    required this.onPostuler,
    required this.onGoToCv,
  });

  final Offre offre;
  final Candidature? candidature;
  final Cv? cv;
  final VoidCallback onPostuler;
  final VoidCallback onGoToCv;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Header(offre: offre),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offre.titre, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TypeBadge(type: offre.type),
                        if (offre.pilier != null) ...[
                          const SizedBox(width: 8),
                          PilierBadge(code: offre.pilier),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (offre.structureNom != null)
                      _InfoLine(
                        icon: Icons.apartment,
                        text: offre.structureNom!,
                      ),
                    if (offre.lieu != null && offre.lieu!.isNotEmpty)
                      _InfoLine(icon: Icons.place_outlined, text: offre.lieu!),
                    _InfoLine(
                      icon: Icons.event,
                      text: 'Date limite : ${formatDate(offre.dateLimite)}',
                    ),
                    _InfoLine(
                      icon: Icons.schedule,
                      text: 'Publiée le ${formatDate(offre.createdAt)}',
                    ),
                    if (offre.description != null &&
                        offre.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle('Description'),
                      Text(
                        offre.description!,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                    if (offre.prerequis != null && offre.prerequis!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle('Prérequis'),
                      Text(
                        offre.prerequis!,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                    if (offre.publicCible != null &&
                        offre.publicCible!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle('Public cible'),
                      Text(
                        offre.publicCible!,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildAction(),
          ),
        ),
      ],
    );
  }

  Widget _buildAction() {
    if (!offre.estOuverte) {
      return const FilledButton(
        onPressed: null,
        child: Text('Offre fermée'),
      );
    }
    final cand = candidature;
    if (cand != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Vous avez postulé : ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              StatutBadge(statut: cand.statut),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Vous serez notifié·e de la décision de la structure.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    // CV manquant ou vide : on bloque la postulation.
    if (cv == null || cv!.estVide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Complète ton CV avant de postuler.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: onGoToCv,
                  child: const Text('Créer mon CV'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.send),
            label: const Text('Postuler'),
          ),
        ],
      );
    }

    return FilledButton.icon(
      onPressed: onPostuler,
      icon: const Icon(Icons.send),
      label: const Text('Postuler'),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.offre});

  final Offre offre;

  @override
  Widget build(BuildContext context) {
    final imageUrl = offre.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _GradientHeader(offre: offre),
        ),
      );
    }
    return _GradientHeader(offre: offre);
  }
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.offre});

  final Offre offre;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E8A93)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.work, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
