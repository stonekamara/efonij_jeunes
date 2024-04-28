import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/commentaire.dart';
import '../../../core/models/communaute.dart';
import '../../../core/models/publication.dart';
import '../../../core/services/supabase_client.dart';

/// Toutes les communautés.
final communautesProvider = FutureProvider<List<Communaute>>((ref) async {
  final rows = await supabase.from('communautes').select().order('nom');
  return rows.map(Communaute.fromMap).toList();
});

/// Ids des communautés dont le jeune est membre.
final mesCommunautesProvider = FutureProvider<Set<String>>((ref) async {
  final rows = await supabase
      .from('communaute_membres')
      .select('communaute_id')
      .eq('user_id', supabase.auth.currentUser!.id);
  return rows
      .map((row) => row['communaute_id'] as String)
      .toSet();
});

/// Détail d'une communauté.
final communauteDetailProvider =
    FutureProvider.family<Communaute, String>((ref, id) async {
  final row = await supabase
      .from('communautes')
      .select()
      .eq('id', id)
      .single();
  return Communaute.fromMap(row);
});

/// Publications du fil d'une communauté (auteur, statut structure, likes,
/// commentaires) — via la fonction RPC fil_communautes.
final publicationsProvider =
    FutureProvider.family<List<Publication>, String>((ref, communauteId) async {
  final rows = await supabase.rpc(
    'fil_communautes',
    params: {'p_communaute_id': communauteId},
  );
  if (rows is! List) return const [];
  return rows
      .map((row) => Publication.fromMap(row as Map<String, dynamic>))
      .toList();
});

/// Commentaires d'une publication.
final commentairesProvider =
    FutureProvider.family<List<Commentaire>, String>((ref, publicationId) async {
  final rows = await supabase
      .from('publication_commentaires')
      .select(
        '*, '
        'profiles!publication_commentaires_auteur_id_fkey(prenom, nom, avatar_url)',
      )
      .eq('publication_id', publicationId)
      .order('created_at');
  return rows.map(Commentaire.fromMap).toList();
});

Future<void> rejoindreCommunaute(String communauteId) async {
  await supabase.from('communaute_membres').insert({
    'communaute_id': communauteId,
    'user_id': supabase.auth.currentUser!.id,
  });
}

Future<void> quitterCommunaute(String communauteId) async {
  await supabase
      .from('communaute_membres')
      .delete()
      .match({
        'communaute_id': communauteId,
        'user_id': supabase.auth.currentUser!.id,
      });
}

Future<void> publierPublication(String communauteId, String contenu) async {
  await supabase.from('publications').insert({
    'communaute_id': communauteId,
    'auteur_id': supabase.auth.currentUser!.id,
    'contenu': contenu,
  });
}

/// Modifie le contenu de sa propre publication (RLS : auteur uniquement).
Future<void> modifierPublication(String publicationId, String contenu) async {
  await supabase
      .from('publications')
      .update({'contenu': contenu})
      .eq('id', publicationId);
}

Future<void> ajouterCommentaire(String publicationId, String contenu) async {
  await supabase.from('publication_commentaires').insert({
    'publication_id': publicationId,
    'auteur_id': supabase.auth.currentUser!.id,
    'contenu': contenu,
  });
}

Future<void> likerPublication(String publicationId) async {
  await supabase.from('publication_likes').insert({
    'publication_id': publicationId,
    'user_id': supabase.auth.currentUser!.id,
  });
}

Future<void> unlikerPublication(String publicationId) async {
  await supabase
      .from('publication_likes')
      .delete()
      .match({
        'publication_id': publicationId,
        'user_id': supabase.auth.currentUser!.id,
      });
}
