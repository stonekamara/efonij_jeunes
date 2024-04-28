# eFonij Jeunes

Application mobile **Flutter** de la plateforme guinéenne d'insertion
professionnelle et entrepreneuriale **FONIJ** : Passeport Jeune (niveaux,
points, piliers SIMANDOU 2040), offres, candidatures (avec CV), communautés,
notifications. Backend : **Supabase** (Postgres + Auth + Storage + Realtime).

Ce dépôt contient le code **côté jeunes**. Le back-office (structures /
admin FONIJ) vit dans le dépôt séparé **`efonij-backoffice`**.

## Stack

- **Flutter** (Dart ≥ 3.12), architecture par feature :
  `lib/features/{auth,onboarding,passeport,offres,candidatures,communautes,profil,cv,notifications,home}`
  et `lib/core/{theme,router,widgets,services,models,constants,utils}`
- **Riverpod** (`Notifier`, `FutureProvider`, `Provider`)
- **go_router** (shell avec barre d'onglets + routes empilées)
- **supabase_flutter** (Auth, Postgres, Storage, Realtime)
- `cached_network_image`, `intl`, `image_picker`, `qr_flutter`, `pdf`,
  `printing`, `url_launcher`
- Couleur principale : `#106067`, mode clair uniquement.

## Prérequis

- Flutter ≥ 3.44 (Dart ≥ 3.12)
- Un projet Supabase (URL + anon key) avec les migrations appliquées
- Un téléphone Android en mode débogage (ou un émulateur) pour tester

## Variables d'environnement

Les credentials passent **exclusivement** par `--dart-define` jamais en dur
dans le code (`lib/core/config.dart`). Sans credentials, l'app affiche un
écran d'aide.

| Variable              | Description                        | Obligatoire |
| --------------------- | ---------------------------------- | ----------- |
| `SUPABASE_URL`        | URL du projet Supabase             | ✅          |
| `SUPABASE_ANON_KEY`   | Clé publique anon du projet        | ✅          |

## Installation & lancement

```bash
flutter pub get

# Lancement en développement (avec credentials)
flutter run \
  --dart-define=SUPABASE_URL=https://XXXX.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# Build APK de debug / release
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://XXXX.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://XXXX.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> 💡 Astuce : définissez `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans un fichier
> `~/.bashrc` (export) pour ne pas les retaper à chaque commande.

## Base de données

Les migrations se trouvent dans `supabase/migrations/`. Appliquez-les **dans
l'ordre** via `supabase db push` ou le SQL Editor du dashboard :

| Migration                       | Contenu                                                                 |
| ------------------------------- | ----------------------------------------------------------------------- |
| `0001_init.sql`                 | Schéma de base (profiles, offres, candidatures, communautés, publications, likes, commentaires), RLS, trigger `handle_new_user`, bucket `avatars` |
| `0002_orgs_qr.sql`              | Matricule FONIJ unique + QR, organisations, `organisation_users`, validations, `is_fonij_admin()` |
| `0003_cv.sql`                   | Tables CV, snapshot PDF des candidatures, bucket `cvs`                  |
| `0004_notifications.sql`        | Table notifications + RLS + Realtime + trigger automatique              |
| `0005_inscriptions.sql`         | Demandes d'inscription des organisations, `demander_acces_organisation` |
| `0006_notifications_details.sql`| Notifications de statut détaillées (titre de l'offre, structure, lieu)  |
| `0007_notifications_delete.sql` | Le jeune peut supprimer ses notifications                               |
| `0008_points.sql`               | Points & progression du Passeport                                       |
| `0008_publications_structures.sql` | Publications des structures dans les communautés + badge structure   |
| `0009_communautes_structures.sql` | Communautés rattachées aux structures, admin des publications        |
| `0010_publications_update.sql`  | Édition/suppression de ses propres publications                         |
| `0011_admin_structures.sql`     | RPC `creer_organisation_par_admin` (création de structures)             |
| `0012_admin_supprime_structures.sql` | RPC `supprimer_organisation_par_admin` (suppression complète)       |
| `0013_perf_indexes.sql`             | Index de performance (offres, candidatures, publications, validations, CV) |

Données de test : `supabase/seed.sql`. Recommandé en dev : désactivez
« Confirm email » dans **Auth → Providers → Email** pour l'enchaînement
inscription → onboarding → home immédiat.

## Fonctionnalités

- **Auth** : inscription, connexion, mot de passe oublié, redirection
  automatique selon l'état du profil (non connecté → login, sans pilier →
  onboarding, profil complet → home).
- **Onboarding & Passeport** : choix d'un pilier SIMANDOU 2040, carte
  « Passeport Jeune » (niveau, points, progression, pilier), QR code du
  matricule scannable par les structures.
- **Offres & candidatures** : liste filtrable (type + pilier), pagination,
  détail, **écran de revue avant candidature** (aperçu du CV + confirmation),
  « Mes candidatures » avec statuts colorés et validations scannées.
- **CV** : construction et édition libre du CV (formations, expériences,
  compétences, langues) ; un snapshot + PDF est joint à chaque candidature.
- **Communautés** : liste, adhésion, fil de publications, like/unlike,
  commentaires (bottom sheet), **posts des structures** (badge structure),
  édition/suppression de ses propres publications.
- **Notifications** : écran dédié, badge, suppression, réception en temps
  réel (Realtime) + notifications automatiques de statut de candidature.
- **Profil** : infos + résumé Passeport, édition, upload d'avatar,
  déconnexion.

## Écarts RLS assumés

Pour que les fils de publications affichent les **auteurs**, deux écarts RLS
minimes (documentés dans les migrations) :

1. `profiles` : `select` ouvert à tout utilisateur connecté (l'écriture reste
   restreinte à sa propre ligne).
2. `publication_likes` : `select` ouvert aux connectés pour compter les likes
   (insert/delete limités à soi-même).

## Tests & analyse

```bash
flutter analyze
flutter test
```
