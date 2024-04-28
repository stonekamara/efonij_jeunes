import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/piliers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../profil/models/profile.dart';
import '../profil/providers/profil_provider.dart';
import 'carte_fonij_card.dart';
import 'passeport_service.dart';

/// Écran « Mon passeport » : le Passeport Jeune est affiché sous la forme
/// d'une carte bancaire E-FONIJ (matricule, titulaire, validité, niveau,
/// pilier) suivie du QR code scannable par les partenaires.
class PasseportScreen extends ConsumerWidget {
  const PasseportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profilProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon passeport')),
      body: AsyncView<Profile>(
        value: profileAsync,
        onRetry: () => ref.invalidate(profilProvider),
        builder: (context, profile) {
          final level = niveauFromNumero(profile.niveauPasseport);
          final pilier = Pilier.fromCode(profile.pilier);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CarteFonijCard(
                niveau: profile.niveauPasseport,
                pilierCode: profile.pilier,
                userId: profile.id,
                prenom: profile.prenom,
                nom: profile.nom,
                matricule: profile.matricule,
                region: profile.region,
                points: profile.points,
              ),
              const SizedBox(height: 16),
              _QrCodeCard(userId: profile.id),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.eco,
                title: 'Niveau ${profile.niveauPasseport} — ${level.nom}',
                subtitle: level.description,
                accent: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _PointsProgressCard(
                points: profile.points,
                niveau: profile.niveauPasseport,
              ),
              const SizedBox(height: 12),
              if (pilier != null)
                _InfoCard(
                  icon: pilier.icon,
                  title: 'Votre pilier : ${pilier.nom}',
                  subtitle: pilier.description,
                  accent: pilier.color,
                ),
              const SizedBox(height: 12),
              const _InfoCard(
                icon: Icons.emoji_events_outlined,
                title: 'Comment gagner des points ?',
                subtitle:
                    'Complétez des modules, postulez à des offres, participez '
                    'aux communautés et validez des activités : chaque preuve '
                    'validée fait progresser votre Passeport Jeune.',
                accent: AppColors.accent,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// QR code du Passeport Jeune, scannable par les partenaires.
class _QrCodeCard extends StatelessWidget {
  const _QrCodeCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE7E5)),
              ),
              child: QrImageView(
                data: 'EFONIJ:$userId',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0A4449),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0A4449),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.qr_code_2, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR code Passeport Jeune',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Présente ce QR code aux structures et entreprises partenaires '
              'pour valider ta présence ou ta candidature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « Mes points » : solde actuel + progression vers le niveau supérieur.
class _PointsProgressCard extends StatelessWidget {
  const _PointsProgressCard({required this.points, required this.niveau});

  final int points;
  final int niveau;

  @override
  Widget build(BuildContext context) {
    final prog = progression(niveau, points);
    final prochainNiveau = niveau >= 4
        ? null
        : niveauxPasseport[niveau] ;
    final niveauNom = niveauFromNumero(niveau).nom;
    final prochainNom = prochainNiveau?.nom;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stars_outlined,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$points points',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prochainNom == null
                            ? 'Niveau maximal atteint !'
                            : 'Progression vers $prochainNom',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prog.progress,
                minHeight: 10,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$niveauNom · $points/${prog.seuil} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${pourcentageProgression(niveau, points)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
