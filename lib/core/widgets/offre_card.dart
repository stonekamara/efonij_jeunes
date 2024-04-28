import 'package:flutter/material.dart';

import '../models/offre.dart';
import '../theme/app_theme.dart';
import '../utils/time_ago.dart';
import 'badges.dart';

/// Carte d'offre compacte (liste des offres, accueil, candidatures).
class OffreCard extends StatelessWidget {
  const OffreCard({super.key, required this.offre, this.onTap});

  final Offre offre;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TypeBadge(type: offre.type),
                        if (offre.pilier != null) ...[
                          const SizedBox(width: 6),
                          PilierBadge(code: offre.pilier),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offre.titre,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (offre.structureNom != null) ...[
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.apartment,
                        text: offre.structureNom!,
                      ),
                    ],
                    if (offre.lieu != null && offre.lieu!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(icon: Icons.place_outlined, text: offre.lieu!),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Limite : ${formatDate(offre.dateLimite)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit aperçu d'offre (utilisé sur l'accueil).
class MiniOffreTile extends StatelessWidget {
  const MiniOffreTile({super.key, required this.offre, this.onTap});

  final Offre offre;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: TypeBadge(type: offre.type),
        title: Text(
          offre.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          offre.structureNom ?? (offre.lieu ?? ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black.withValues(alpha: 0.4)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
