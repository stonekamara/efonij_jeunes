import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/candidatures/screens/candidatures_screen.dart';
import '../../features/cv/cv_screen.dart';
import '../../features/offres/screens/candidature_review_screen.dart';
import '../../features/communautes/screens/communaute_detail_screen.dart';
import '../../features/communautes/screens/communautes_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/offres/screens/offre_detail_screen.dart';
import '../../features/offres/screens/offres_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/passeport/passeport_screen.dart';
import '../../features/profil/screens/edit_profil_screen.dart';
import '../../features/profil/screens/profil_screen.dart';
import '../widgets/main_shell.dart';

/// Routeur principal avec redirections basées sur l'authentification :
/// - non connecté → /login
/// - connecté sans pilier choisi → /onboarding
/// - profil complet → /home
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: ref.read(authRefreshProvider),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (!auth.isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }
      if (isAuthRoute) return '/home';
      if (auth.profile == null) return null; // profil en cours de chargement
      if (auth.needsOnboarding && location != '/onboarding') return '/onboarding';
      if (!auth.needsOnboarding && location == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/offres',
                builder: (context, state) => const OffresScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/communautes',
                builder: (context, state) => const CommunautesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) => const ProfilScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/offres/:id',
        builder: (context, state) =>
            OffreDetailScreen(offreId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/offres/:id/postuler',
        builder: (context, state) => CandidatureReviewScreen(
          offreId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/candidatures',
        builder: (context, state) => const CandidaturesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/passeport',
        builder: (context, state) => const PasseportScreen(),
      ),
      GoRoute(
        path: '/cv',
        builder: (context, state) => const CvScreen(),
      ),
      GoRoute(
        path: '/communautes/:id',
        builder: (context, state) =>
            CommunauteDetailScreen(communauteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/edit-profil',
        builder: (context, state) => const EditProfilScreen(),
      ),
    ],
  );
});
