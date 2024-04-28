import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client.dart';
import '../../candidatures/providers/candidatures_provider.dart';
import '../../communautes/providers/communautes_provider.dart';
import '../../profil/models/profile.dart';
import '../../profil/providers/profil_provider.dart';

/// État d'authentification global, utilisé pour les redirections du router.
class AppAuthState {
  const AppAuthState({this.session, this.profile, this.loadingProfile = false});

  final Session? session;
  final Profile? profile;

  /// Vrai tant que le profil n'a pas encore été rechargé après connexion.
  final bool loadingProfile;

  bool get isLoggedIn => session != null;

  bool get needsOnboarding => isLoggedIn && (profile == null || !profile!.aChoisiPilier);
}

/// Notifie le router pour qu'il ré-évalue les redirections.
class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshProvider =
    Provider<AuthRefreshNotifier>((ref) => AuthRefreshNotifier());

final authControllerProvider =
    NotifierProvider<AuthController, AppAuthState>(AuthController.new);

/// Écoute `onAuthStateChange` et charge le profil du jeune connecté.
class AuthController extends Notifier<AppAuthState> {
  StreamSubscription<AuthState>? _authSub;
  String? _lastUserId;

  @override
  AppAuthState build() {
    final session = supabase.auth.currentSession;

    _authSub = supabase.auth.onAuthStateChange.listen((authState) {
      final newSession = authState.session;
      if (newSession == null) {
        state = const AppAuthState();
      } else {
        state = AppAuthState(session: newSession, loadingProfile: true);
        unawaited(_loadProfile(newSession.user.id));
      }
      _handleUserSwitch(newSession);
      ref.read(authRefreshProvider).refresh();
    });
    ref.onDispose(() => _authSub?.cancel());

    if (session != null) {
      unawaited(_loadProfile(session.user.id));
      _lastUserId = session.user.id;
      return AppAuthState(session: session, loadingProfile: true);
    }
    return const AppAuthState();
  }

  /// Purge les caches liés à l'utilisateur (déconnexion ou changement de compte)
  /// pour éviter d'afficher les données d'un ancien compte.
  void _handleUserSwitch(Session? session) {
    final uid = session?.user.id;
    if (uid == _lastUserId) return;
    _lastUserId = uid;
    ref.invalidate(profilProvider);
    ref.invalidate(candidaturesProvider);
    ref.invalidate(mesCommunautesProvider);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final row = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      state = AppAuthState(
        session: supabase.auth.currentSession,
        profile: row == null ? null : Profile.fromJson(row),
      );
    } catch (_) {
      state = AppAuthState(
        session: supabase.auth.currentSession,
        loadingProfile: false,
      );
    }
    ref.read(authRefreshProvider).refresh();
  }

  /// Recharge le profil (ex. après l'onboarding ou une mise à jour).
  Future<void> refreshProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await _loadProfile(user.id);
  }

  Future<void> signOut() => supabase.auth.signOut();
}
