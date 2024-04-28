import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/candidature.dart';
import '../../../core/models/validation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/candidatures_provider.dart';

class CandidaturesScreen extends ConsumerWidget {
  const CandidaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidaturesAsync = ref.watch(candidaturesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes candidatures')),
      body: AsyncView<List<Candidature>>(
        value: candidaturesAsync,
        onRetry: () => ref.invalidate(candidaturesProvider),
        builder: (context, candidatures) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(candidaturesProvider),
            child: candidatures.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'Aucune candidature',
                        message:
                            'Parcourez les offres et postulez pour les retrouver ici.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: candidatures.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _CandidatureCard(candidature: candidatures[index]);
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _CandidatureCard extends StatelessWidget {
  const _CandidatureCard({required this.candidature});

  final Candidature candidature;

  Future<void> _openCv(BuildContext context) async {
    final url = candidature.cvPdfUrl;
    if (url == null || url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le CV.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offre = candidature.offre;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: offre == null
            ? null
            : () => context.push('/offres/${offre.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offre?.titre ?? 'Offre supprimée',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatutBadge(statut: candidature.statut),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (offre != null) ...[
                    TypeBadge(type: offre.type),
                    const SizedBox(width: 6),
                    PilierBadge(code: offre.pilier),
                    const Spacer(),
                  ],
                  Text(
                    'Postulée ${timeAgo(candidature.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (candidature.validations.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final validation in candidature.validations) ...[
                  ValidationBadge(validation: validation),
                  const SizedBox(height: 6),
                ],
              ],
              if (candidature.cvPdfUrl != null &&
                  candidature.cvPdfUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openCv(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Voir mon CV envoyé'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de validation apportée par une organisation partenaire (scan QR).
class ValidationBadge extends StatelessWidget {
  const ValidationBadge({super.key, required this.validation});

  final Validation validation;

  @override
  Widget build(BuildContext context) {
    final color = validation.estPresence
        ? AppColors.pilierAg
        : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${validation.libelle} le ${_dateFr(validation.scannedAt)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateFr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.'
    '${d.year}';
