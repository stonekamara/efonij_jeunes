import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/piliers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../auth/providers/auth_controller.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../passeport/carte_fonij_card.dart';
import '../models/profile.dart';
import '../providers/profil_provider.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour accéder à votre compte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      // Le router redirige vers /login automatiquement.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: AsyncView<Profile>(
        value: profileAsync,
        onRetry: () => ref.invalidate(profilProvider),
        builder: (context, profile) {
          final pilier = Pilier.fromCode(profile.pilier);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(profile: profile),
              const SizedBox(height: 16),
              CarteFonijCard(
                niveau: profile.niveauPasseport,
                pilierCode: profile.pilier,
                userId: profile.id,
                prenom: profile.prenom,
                nom: profile.nom,
                matricule: profile.matricule,
                region: profile.region,
                points: profile.points,
                compact: true,
                onTap: () => context.push('/passeport'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline,
                      label: pilier == null
                          ? 'Aucun pilier choisi'
                          : 'Pilier ${pilier.code} — ${pilier.nom}',
                      value: null,
                    ),
                    if (profile.region != null && profile.region!.isNotEmpty)
                      _InfoTile(
                        icon: Icons.place_outlined,
                        label: profile.region!,
                        value: null,
                      ),
                    if (profile.telephone != null &&
                        profile.telephone!.isNotEmpty)
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: profile.telephone!,
                        value: null,
                      ),
                    _InfoTile(
                      icon: Icons.mail_outline,
                      label: profile.email,
                      value: null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Modifier le profil'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/edit-profil'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Mes notifications'),
                      subtitle: _NotificationsSubtitle(),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/notifications'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: const Text('Mes candidatures'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/candidatures'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Mon CV'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/cv'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.eco_outlined),
                      title: const Text('Mon passeport'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/passeport'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E8A93)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          AvatarView(
            url: profile.avatarUrl,
            prenom: profile.prenom,
            nom: profile.nom,
            size: 64,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jeune E-FONIJ — ${profile.points} pts · niveau ${profile.niveauPasseport}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sous-titre « Mes notifications » : affiche le nombre de non-lues.
class _NotificationsSubtitle extends ConsumerWidget {
  const _NotificationsSubtitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    if (unread == 0) return const SizedBox.shrink();
    return Text(
      '$unread non lue${unread > 1 ? 's' : ''}',
      style: const TextStyle(color: AppColors.danger, fontSize: 12),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: value == null ? null : Text(value!),
    );
  }
}
