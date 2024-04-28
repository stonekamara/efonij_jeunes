import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/candidature.dart';
import '../../../core/services/supabase_client.dart';

/// Candidatures du jeune connecté, avec l'offre associée.
final candidaturesProvider = FutureProvider<List<Candidature>>((ref) async {
  final rows = await supabase
      .from('candidatures')
      .select('*, offres(*), validations(*)')
      .order('created_at', ascending: false);
  return rows.map(Candidature.fromMap).toList();
});
