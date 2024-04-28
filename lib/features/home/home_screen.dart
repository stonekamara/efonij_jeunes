import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/avatar_view.dart';
import '../notifications/providers/notifications_provider.dart';
import '../../core/widgets/offre_card.dart' show MiniOffreTile;
import '../../features/offres/providers/offres_controller.dart';
import '../../features/passeport/carte_fonij_card.dart';
import '../../features/profil/models/profile.dart';
import '../../features/profil/providers/profil_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(offresControllerProvider.notifier);
      if (ref.read(offresControllerProvider).offres.isEmpty) {
        controller.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profilProvider);
    final offresState = ref.watch(offresControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-FONIJ'),
        actions: [
          _NotificationsBell(),
          profileAsync.maybeWhen(
            data: (profile) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => context.go('/profil'),
                child: AvatarView(
                  url: profile.avatarUrl,
                  prenom: profile.prenom,
                  nom: profile.nom,
                  size: 34,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncView<Profile>(
        value: profileAsync,
        onRetry: () => ref.invalidate(profilProvider),
        builder: (context, profile) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profilProvider);
              await ref.read(offresControllerProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${profile.prenom} 👋',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Votre parcours vers l\'insertion professionnelle',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                const _QuickActionsGrid(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Dernières offres',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/offres'),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (offresState.isLoading && offresState.offres.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (offresState.offres.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune offre pour le moment. Revenez bientôt !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final offre in offresState.offres.take(3)) ...[
                    MiniOffreTile(
                      offre: offre,
                      onTap: () => context.push('/offres/${offre.id}'),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Cloche de notifications avec badge du nombre de non-lues.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        onPressed: () => context.push('/notifications'),
        tooltip: 'Mes notifications',
        icon: Badge.count(
          count: unread,
          isLabelVisible: unread > 0,
          backgroundColor: AppColors.danger,
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _QuickAction(
          icon: Icons.work,
          color: AppColors.pilierEd,
          label: 'Offres',
          onTap: () => context.go('/offres'),
        ),
        _QuickAction(
          icon: Icons.assignment,
          color: AppColors.success,
          label: 'Mes candidatures',
          onTap: () => context.push('/candidatures'),
        ),
        _QuickAction(
          icon: Icons.groups,
          color: AppColors.pilierIt,
          label: 'Communautés',
          onTap: () => context.go('/communautes'),
        ),
        _QuickAction(
          icon: Icons.eco,
          color: AppColors.pilierAg,
          label: 'Mon passeport',
          onTap: () => context.push('/passeport'),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EEEC)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
