import 'package:efonij_jeunes/core/models/offre.dart';
import 'package:efonij_jeunes/features/cv/models/cv.dart';
import 'package:efonij_jeunes/features/cv/providers/cv_provider.dart';
import 'package:efonij_jeunes/features/offres/providers/offre_detail_providers.dart';
import 'package:efonij_jeunes/features/offres/screens/candidature_review_screen.dart';
import 'package:efonij_jeunes/features/profil/models/profile.dart';
import 'package:efonij_jeunes/features/profil/providers/profil_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _offre = Offre(
  id: 'o1',
  titre: 'Développeur Flutter junior',
  type: 'emploi',
  pilier: 'IT',
  lieu: 'Conakry',
  structureNom: 'Structure Test',
  dateLimite: DateTime(2026, 9, 30),
  createdAt: DateTime(2026, 8, 1),
);

final _profile = Profile(
  id: 'u1',
  prenom: 'Aïcha',
  nom: 'Diallo',
  email: 'aicha.diallo@exemple.gn',
  telephone: '+224 620 00 00 00',
  region: 'Conakry',
  pilier: 'IT',
  niveauPasseport: 2,
  points: 150,
  matricule: 'FONIJ-26-000789',
);

Cv _cvComplet() => Cv(
      userId: 'u1',
      titrePoste: 'Développeur Flutter',
      resume: 'Passionné par le développement mobile.',
      formations: const [
        CvFormation(
          diplome: 'Licence Informatique',
          etablissement: 'Université de Conakry',
          anneeDebut: 2021,
          anneeFin: 2024,
        ),
      ],
      experiences: const [
        CvExperience(
          poste: 'Stagiaire développeur',
          organisation: 'Startup GN',
        ),
      ],
      competences: const [CvCompetence(nom: 'Flutter'), CvCompetence(nom: 'SQL')],
      langues: const [CvLangue(langue: 'Français', niveau: 'courant')],
    );

Widget _app({required Cv? cv}) {
  final router = GoRouter(
    initialLocation: '/offres/o1/postuler',
    routes: [
      GoRoute(
        path: '/offres/:id/postuler',
        builder: (context, state) =>
            CandidatureReviewScreen(offreId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cv',
        builder: (context, state) => const Scaffold(body: Text('Écran CV')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      offreDetailProvider.overrideWith((ref, id) async => _offre),
      profilProvider.overrideWith((ref) async => _profile),
      cvProvider.overrideWith((ref) async => cv),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('CandidatureReviewScreen', () {
    testWidgets(
        'affiche l\'offre, l\'aperçu du CV complet et les boutons d\'action',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(cv: _cvComplet()));
      await tester.pumpAndSettle();

      // Titre d'écran + encart offre.
      expect(find.text('Confirmer ma candidature'), findsOneWidget);
      expect(find.text('Vous postulez à'), findsOneWidget);
      expect(find.text('Développeur Flutter junior'), findsOneWidget);
      expect(find.text('Structure Test'), findsOneWidget);

      // Aperçu du CV : identité, coordonnées, sections.
      expect(find.text('CV qui sera envoyé'), findsOneWidget);
      expect(find.text('Aïcha Diallo'), findsOneWidget);
      expect(find.text('aicha.diallo@exemple.gn'), findsOneWidget);
      expect(find.text('+224 620 00 00 00'), findsOneWidget);
      expect(find.text('Développeur Flutter'), findsOneWidget);
      expect(find.text('Licence Informatique'), findsOneWidget);
      expect(find.textContaining('Université de Conakry'), findsOneWidget);
      expect(find.text('Stagiaire développeur'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);

      // Boutons.
      expect(find.text('Modifier mon CV'), findsOneWidget);
      expect(find.text('Confirmer et envoyer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le bouton « Modifier mon CV » ouvre l\'écran CV',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(cv: _cvComplet()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier mon CV'));
      await tester.pumpAndSettle();

      expect(find.text('Écran CV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche l\'état « CV vide » avec le bouton Créer mon CV',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          cv: Cv(userId: 'u1', resume: '', formations: const []),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ton CV est vide : complète-le avant de postuler.'),
        findsOneWidget,
      );
      expect(find.text('Créer mon CV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('calcule le taux de complétude du CV',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(cv: _cvComplet()));
      await tester.pumpAndSettle();

      // 6 sections renseignées sur 6 → 100%.
      expect(find.text('100% complet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
