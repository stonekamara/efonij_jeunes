import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/commentaire.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/communautes_provider.dart';

class CommentairesSheet extends ConsumerStatefulWidget {
  const CommentairesSheet({
    super.key,
    required this.publicationId,
    required this.communauteId,
  });

  final String publicationId;
  final String communauteId;

  @override
  ConsumerState<CommentairesSheet> createState() => _CommentairesSheetState();
}

class _CommentairesSheetState extends ConsumerState<CommentairesSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final contenu = _controller.text.trim();
    if (contenu.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ajouterCommentaire(widget.publicationId, contenu);
      _controller.clear();
      ref.invalidate(commentairesProvider(widget.publicationId));
      ref.invalidate(publicationsProvider(widget.communauteId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer le commentaire.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentairesAsync =
        ref.watch(commentairesProvider(widget.publicationId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Text(
                'Commentaires',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncView<List<Commentaire>>(
            value: commentairesAsync,
            onRetry: () =>
                ref.invalidate(commentairesProvider(widget.publicationId)),
            builder: (context, commentaires) {
              if (commentaires.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Aucun commentaire',
                  message: 'Soyez le premier à commenter !',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: commentaires.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final commentaire = commentaires[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarView(
                        url: commentaire.auteurAvatarUrl,
                        prenom: commentaire.auteurPrenom ?? '',
                        nom: commentaire.auteurNom ?? '',
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      commentaire.auteurAffichable,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeAgo(commentaire.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(commentaire.contenu),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Écrire un commentaire…',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
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
        ),
      ],
    );
  }
}
