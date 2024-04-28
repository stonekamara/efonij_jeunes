import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Initialise le client Supabase avec les credentials `--dart-define`.
///
/// À n'appeler que si [AppConfig.hasSupabaseCredentials] est vrai.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // Vérification de la connexion au démarrage (critère d'acceptation étape 1).
  try {
    await Supabase.instance.client.from('offres').select('id').limit(1);
    SupabaseStartup.connected = true;
    debugPrint('[Supabase] Connexion établie avec succès.');
  } catch (e) {
    SupabaseStartup.connected = false;
    SupabaseStartup.error = e.toString();
    debugPrint('[Supabase] Échec de la connexion : $e');
  }
}

/// Résultat de la vérification de connexion au démarrage.
class SupabaseStartup {
  SupabaseStartup._();

  static bool? connected;
  static String? error;
}

/// Client Supabase global. À utiliser uniquement après [initSupabase].
SupabaseClient get supabase => Supabase.instance.client;
