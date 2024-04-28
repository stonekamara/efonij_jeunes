import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client.dart';
import '../models/profile.dart';

class ProfilRepository {
  ProfilRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> values) async {
    await _client.from('profiles').update(values).eq('id', userId);
  }

  /// Envoie l'avatar vers le bucket `avatars` (chemin `<userId>/avatar.<ext>`)
  /// et renvoie son URL publique.
  Future<String?> uploadAvatar(
    String userId,
    Uint8List bytes, {
    String extension = 'jpg',
    String? contentType,
  }) async {
    final path = '$userId/avatar.$extension';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    // Cache-buster : l'URL du fichier est identique à chaque upload, mais
    // AvatarView utilise un cache réseau — sans paramètre unique, l'ancienne
    // photo continuerait d'être affichée après une mise à jour.
    final url = _client.storage.from('avatars').getPublicUrl(path);
    final version = DateTime.now().millisecondsSinceEpoch;
    return url.contains('?') ? '$url&v=$version' : '$url?v=$version';
  }
}

final profilRepositoryProvider =
    Provider<ProfilRepository>((ref) => ProfilRepository(supabase));
