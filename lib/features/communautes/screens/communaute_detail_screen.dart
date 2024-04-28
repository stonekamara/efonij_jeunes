import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/piliers.dart';
import '../../../core/models/communaute.dart';
import '../../../core/models/publication.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/communautes_provider.dart';
import 'commentaires_sheet.dart';

class CommunauteDetailScreen extends ConsumerStatefulWidget {
  const CommunauteDetailScreen({super.key, required this.communauteId});

  final String communauteId;

  @override
  ConsumerState<CommunauteDetailScreen> createState() =>
      _CommunauteDetailScreenState();
}

class _CommunauteDetailScreenState extends ConsumerState<CommunauteDetailScreen> {
  final _postController = TextEditingController();
  bool _posting = false;
  bool _joining = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _publier() async {
    final contenu = _postController.text.trim();
    if (contenu.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await publierPublication(widget.communauteId, contenu);
      _postController.clear();
      ref.invalidate(publicationsProvider(widget.communauteId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de publier. Réessayez.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleMembre(bool estMembre) async {
    setState(() => _joining = true);
    try {
      if (estMembre) {
        await quitterCommunaute(widget.communauteId);
      } else {
        await rejoindreCommunaute(widget.communauteId);
      }
      ref.invalidate(mesCommunautesProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de mettre à jour votre adhésion.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final communauteAsync =
        ref.watch(communauteDetailProvider(widget.communauteId));
    final estMembre =
        ref.watch(mesCommunautesProvider).value?.contains(widget.communauteId) ??
            false;

    return Scaffold(
      body: AsyncView<Communaute>(
        value: communauteAsync,
        onRetry: () =>
            ref.invalidate(communauteDetailProvider(widget.communauteId)),
        builder: (context, communaute) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(publicationsProvider(widget.communauteId));
              await ref.read(publicationsProvider(widget.communauteId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 280,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        child: estMembre
                            ? OutlinedButton.icon(
                                onPressed: _joining
                                    ? null
                                    : () => _toggleMembre(estMembre),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white70,
                                    width: 1.4,
                                  ),
                                ),
                                icon: const Icon(Icons.logout, size: 16),
                                label: const Text('Quitter'),
                              )
                            : FilledButton.icon(
                                onPressed: _joining
                                    ? null
                                    : () => _toggleMembre(estMembre),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Rejoindre'),
                              ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 72,
                      bottom: 12,
                      end: 128,
                    ),
                    title: Text(
                      communaute.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    background: _HeaderBackground(communaute: communaute),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Fil de la communauté',
                              style:
                                  Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            if (estMembre)
                              const Text(
                                'Vous êtes membre',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        if (estMembre) ...[
                          const SizedBox(height: 10),
                          _PostForm(
                            controller: _postController,
                            posting: _posting,
                            onSend: _publier,
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _Feed(
                      communauteId: widget.communauteId,
                      estMembre: estMembre,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.communaute});

  final Communaute communaute;

  @override
  Widget build(BuildContext context) {
    final pilier = Pilier.fromCode(communaute.pilier);
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'COMMUNAUTÉ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AvatarView(
                url: communaute.avatarUrl,
                prenom: communaute.nom,
                nom: '',
                size: 44,
              ),
              const SizedBox(width: 12),
              if (pilier != null) PilierBadge(code: communaute.pilier),
            ],
          ),
          if (communaute.description != null &&
              communaute.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              communaute.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostForm extends StatelessWidget {
  const _PostForm({
    required this.controller,
    required this.posting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool posting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Partagez quelque chose avec la communauté…',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: posting ? null : onSend,
              icon: posting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.communauteId, required this.estMembre});

  final String communauteId;
  final bool estMembre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicationsAsync = ref.watch(publicationsProvider(communauteId));

    return AsyncView<List<Publication>>(
      value: publicationsAsync,
      onRetry: () => ref.invalidate(publicationsProvider(communauteId)),
      builder: (context, publications) {
        if (publications.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              icon: Icons.forum_outlined,
              title: 'Aucune publication',
              message: estMembre
                  ? 'Lancez la conversation !'
                  : 'Rejoignez la communauté pour publier.',
            ),
          );
        }
        return Column(
          children: [
            for (final publication in publications) ...[
              _PublicationCard(
                publication: publication,
                communauteId: communauteId,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _PublicationCard extends ConsumerWidget {
  const _PublicationCard({
    required this.publication,
    required this.communauteId,
  });

  final Publication publication;
  final String communauteId;

  Future<void> _toggleLike(WidgetRef ref, BuildContext context) async {
    try {
      if (publication.likedByMe) {
        await unlikerPublication(publication.id);
      } else {
        await likerPublication(publication.id);
      }
      ref.invalidate(publicationsProvider(communauteId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action impossible. Réessayez.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _openCommentaires(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: CommentairesSheet(
            publicationId: publication.id,
            communauteId: communauteId,
          ),
        ),
      ),
    );
  }

  void _openEdition(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _EditerPublicationSheet(
          publication: publication,
          onSaved: () =>
              ref.invalidate(publicationsProvider(communauteId)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine =
        publication.auteurId == supabase.auth.currentUser?.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarView(
                  url: publication.auteurAvatarUrl,
                  prenom: publication.auteurPrenom ?? '',
                  nom: publication.auteurNom ?? '',
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.auteurAffichable,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        timeAgo(publication.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (publication.estStructure)
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: AppColors.primary,
                  ),
                if (isMine)
                  IconButton(
                    onPressed: () => _openEdition(context, ref),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Modifier mon post',
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(publication.contenu),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: publication.likedByMe
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: publication.likedByMe
                      ? AppColors.danger
                      : AppColors.textSecondary,
                  label: '${publication.likesCount}',
                  onTap: () => _toggleLike(ref, context),
                ),
                const SizedBox(width: 16),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.textSecondary,
                  label: '${publication.commentairesCount}',
                  onTap: () => _openCommentaires(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille d'édition d'une publication (uniquement ses propres posts).
class _EditerPublicationSheet extends ConsumerStatefulWidget {
  const _EditerPublicationSheet({
    required this.publication,
    required this.onSaved,
  });

  final Publication publication;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditerPublicationSheet> createState() =>
      _EditerPublicationSheetState();
}

class _EditerPublicationSheetState
    extends ConsumerState<_EditerPublicationSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.publication.contenu);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final contenu = _controller.text.trim();
    if (contenu.isEmpty || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await modifierPublication(widget.publication.id, contenu);
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Post modifié.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de modifier. Réessayez.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifier mon post',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Votre message…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _enregistrer,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
