import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/piliers.dart';
import '../../../core/models/communaute.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/communautes_provider.dart';

class CommunautesScreen extends ConsumerWidget {
  const CommunautesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communautesAsync = ref.watch(communautesProvider);
    final mesCommunautes = ref.watch(mesCommunautesProvider).value ?? const <String>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Communautés')),
      body: AsyncView<List<Communaute>>(
        value: communautesAsync,
        onRetry: () => ref.invalidate(communautesProvider),
        builder: (context, communautes) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(communautesProvider);
              ref.invalidate(mesCommunautesProvider);
              await ref.read(communautesProvider.future);
            },
            child: communautes.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      EmptyState(
                        icon: Icons.groups,
                        title: 'Aucune communauté',
                        message: 'Les communautés apparaîtront ici.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: communautes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final communaute = communautes[index];
                      return _CommunauteCard(
                        communaute: communaute,
                        isMember: mesCommunautes.contains(communaute.id),
                        onTap: () =>
                            context.push('/communautes/${communaute.id}'),
                        onToggleMembre: () async {
                          try {
                            if (mesCommunautes.contains(communaute.id)) {
                              await quitterCommunaute(communaute.id);
                            } else {
                              await rejoindreCommunaute(communaute.id);
                            }
                            ref.invalidate(mesCommunautesProvider);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Impossible de mettre à jour votre adhésion.',
                                  ),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _CommunauteCard extends StatelessWidget {
  const _CommunauteCard({
    required this.communaute,
    required this.isMember,
    required this.onTap,
    required this.onToggleMembre,
  });

  final Communaute communaute;
  final bool isMember;
  final VoidCallback onTap;
  final VoidCallback onToggleMembre;

  @override
  Widget build(BuildContext context) {
    final pilier = Pilier.fromCode(communaute.pilier);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarView(
                url: communaute.avatarUrl,
                prenom: communaute.nom,
                nom: '',
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            communaute.nom,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (pilier != null)
                          PilierBadge(code: communaute.pilier, compact: true),
                      ],
                    ),
                    if (communaute.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        communaute.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: isMember
                          ? OutlinedButton.icon(
                              onPressed: onToggleMembre,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                foregroundColor: AppColors.primary,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Membre'),
                            )
                          : FilledButton.tonalIcon(
                              onPressed: onToggleMembre,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Rejoindre'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
