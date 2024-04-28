import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_client.dart';
import '../data/cv_repository.dart';
import '../models/cv.dart';

/// Repository partagé pour tout le feature CV.
final cvRepositoryProvider = Provider<CvRepository>((ref) => CvRepository());

/// CV courant de l'utilisateur connecté (null si jamais créé).
final cvProvider = FutureProvider<Cv?>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  return ref.read(cvRepositoryProvider).charger(user.id);
});
