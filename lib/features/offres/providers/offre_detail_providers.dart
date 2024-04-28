import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/candidature.dart';
import '../../../core/models/offre.dart';
import '../../../core/services/supabase_client.dart';

/// Détail d'une offre (avec le nom de l'organisation qui la publie).
final offreDetailProvider = FutureProvider.family<Offre, String>(
  (ref, id) async {
    final row = await supabase
        .from('offres')
        .select('*, organisations(nom)')
        .eq('id', id)
        .single();
    return Offre.fromMap(row);
  },
);

/// Candidature éventuelle de l'utilisateur connecté sur une offre donnée.
final candidatureForOffreProvider = FutureProvider.family<Candidature?, String>(
  (ref, offreId) async {
    final row = await supabase
        .from('candidatures')
        .select()
        .eq('offre_id', offreId)
        .eq('user_id', supabase.auth.currentUser!.id)
        .maybeSingle();
    return row == null ? null : Candidature.fromMap(row);
  },
);
