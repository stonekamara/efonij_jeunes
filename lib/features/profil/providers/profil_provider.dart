import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_client.dart';
import '../data/profil_repository.dart';
import '../models/profile.dart';

/// Profil complet du jeune connecté.
final profilProvider = FutureProvider<Profile>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw StateError('Non connecté');
  }
  final profile = await ref.watch(profilRepositoryProvider).getProfile(user.id);
  if (profile == null) {
    throw StateError('Profil introuvable');
  }
  return profile;
});
