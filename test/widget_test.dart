import 'package:efonij_jeunes/core/models/candidature.dart';
import 'package:efonij_jeunes/core/models/validation.dart';
import 'package:efonij_jeunes/features/candidatures/screens/candidatures_screen.dart';
import 'package:efonij_jeunes/features/passeport/carte_fonij_card.dart';
import 'package:efonij_jeunes/features/passeport/passeport_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('CarteFonijCard', () {
    testWidgets('affiche le matricule comme numéro de carte',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CarteFonijCard(
              niveau: 1,
              pilierCode: 'AG',
              matricule: 'FONIJ-26-000123',
            ),
          ),
        ),
      );

      expect(find.text('E-FONIJ'), findsOneWidget);
      expect(find.text('PASSEPORT JEUNE'), findsOneWidget);
      expect(find.text('FONIJ 26 000123'), findsOneWidget);
      expect(find.text('TITULAIRE'), findsOneWidget);
      expect(find.text('AG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche le niveau sans matricule (numéro de secours)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CarteFonijCard(niveau: 3, pilierCode: 'IT'),
          ),
        ),
      );

      expect(find.text('3 · ARBRE'), findsOneWidget);
      expect(find.text('VALIDITÉ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('au niveau 4, la carte indique le niveau Forêt',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CarteFonijCard(niveau: 4, pilierCode: null),
          ),
        ),
      );

      expect(find.text('4 · FORÊT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche titulaire et validité à partir de l\'identité',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarteFonijCard(
              niveau: 2,
              pilierCode: 'IT',
              userId: 'test-user-123',
              prenom: 'Aïssata',
              nom: 'Soumah',
              matricule: 'FONIJ-26-000456',
            ),
          ),
        ),
      );

      expect(find.text('SOUMAH AÏSSATA'), findsOneWidget);
      expect(find.text('FONIJ 26 000456'), findsOneWidget);
      expect(find.text('VALIDITÉ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('se retourne au toucher pour révéler la face arrière',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarteFonijCard(
              niveau: 2,
              pilierCode: 'IT',
              userId: 'test-user-123',
              prenom: 'Aïssata',
              nom: 'Soumah',
              matricule: 'FONIJ-26-000456',
            ),
          ),
        ),
      );

      // Face avant visible au départ.
      expect(find.text('FONIJ 26 000456'), findsOneWidget);
      expect(find.text('SIGNATURE'), findsNothing);

      // Toucher la carte → animation de flip → face arrière.
      await tester.tap(find.byType(CarteFonijCard));
      await tester.pumpAndSettle();

      expect(find.text('SIGNATURE'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('SANS CONTACT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('en mode compact, onTap externe est utilisé sans retournement',
        (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarteFonijCard(
              niveau: 1,
              pilierCode: 'AG',
              compact: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Touchez pour retourner'), findsNothing);
      await tester.tap(find.byType(CarteFonijCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.text('SIGNATURE'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('identitePasseport (MRZ)', () {
    test('est déterministe : même userId → même n° et même MRZ', () {
      final a = identitePasseport(userId: 'u-42', prenom: 'Mariama', nom: 'Diallo');
      final b = identitePasseport(userId: 'u-42', prenom: 'Mariama', nom: 'Diallo');
      expect(a.numero, b.numero);
      expect(a.mrzLigne1, b.mrzLigne1);
      expect(a.mrzLigne2, b.mrzLigne2);
      expect(a.dateNaissance, b.dateNaissance);
    });

    test('génère des numéros différents pour des comptes différents', () {
      final a = identitePasseport(userId: 'u-1', prenom: 'X', nom: 'Y');
      final b = identitePasseport(userId: 'u-2', prenom: 'X', nom: 'Y');
      expect(a.numero, isNot(b.numero));
    });

    test('les deux lignes MRZ font 44 caractères, ligne 1 = P<GIN', () {
      final id = identitePasseport(userId: 'u-7', prenom: 'Alpha', nom: 'Bah');
      expect(id.mrzLigne1.length, 44);
      expect(id.mrzLigne2.length, 44);
      expect(id.mrzLigne1.startsWith('P<GIN'), isTrue);
      expect(id.mrzLigne1, contains('ALPHA'));
    });

    test('les chiffres de contrôle de la ligne 2 sont valides (ICAO 9303)', () {
      final id = identitePasseport(userId: 'u-9', prenom: 'Fatoumata', nom: 'Kéïta');
      final l2 = id.mrzLigne2;

      String cd(String s) {
        const weights = [7, 3, 1];
        var sum = 0;
        for (var i = 0; i < s.length; i++) {
          final c = s.codeUnitAt(i);
          final value = (c >= 0x30 && c <= 0x39)
              ? c - 0x30
              : (c >= 0x41 && c <= 0x5A)
                  ? c - 0x41 + 10
                  : 0;
          sum += value * weights[i % 3];
        }
        return (sum % 10).toString();
      }

      expect(l2[9], cd(l2.substring(0, 9))); // n° de passeport
      expect(l2[19], cd(l2.substring(13, 19))); // date de naissance
      expect(l2[27], cd(l2.substring(21, 27))); // expiration
      expect(l2[42], cd(l2.substring(28, 42))); // numéro personnel
      expect(l2[43], cd(l2.substring(0, 43))); // contrôle global
    });

    test('les accents sont normalisés dans la MRZ', () {
      final id = identitePasseport(
        userId: 'u-3',
        prenom: 'Aïssatou',
        nom: 'Camara',
      );
      expect(id.mrzLigne1, contains('AISSATOU'));
      expect(id.mrzLigne1, isNot(contains('AÏ')));
    });
  });

  group('Validation', () {
    test('fromMap parse présence et libellé', () {
      final v = Validation.fromMap(const {
        'id': 'v1',
        'candidature_id': 'c1',
        'type': 'presence_evenement',
        'scanned_at': '2026-08-01T10:00:00Z',
      });
      expect(v.estPresence, isTrue);
      expect(v.libelle, 'Présence validée');
      expect(v.scannedAt.year, 2026);
    });

    test('fromMap parse confirmation', () {
      final v = Validation.fromMap(const {
        'id': 'v2',
        'candidature_id': 'c2',
        'type': 'confirmation_candidature',
        'scanned_at': '2026-08-02T10:00:00Z',
      });
      expect(v.estConfirmation, isTrue);
      expect(v.libelle, 'Candidature confirmée');
    });
  });

  group('Candidature', () {
    test('fromMap intègre les validations liées', () {
      final c = Candidature.fromMap(const {
        'id': 'c1',
        'offre_id': 'o1',
        'user_id': 'u1',
        'statut': 'acceptee',
        'created_at': '2026-07-01T10:00:00Z',
        'validations': [
          {
            'id': 'v1',
            'candidature_id': 'c1',
            'type': 'confirmation_candidature',
            'scanned_at': '2026-08-02T10:00:00Z',
          },
        ],
      });
      expect(c.validations, hasLength(1));
      expect(c.validations.first.libelle, 'Candidature confirmée');
    });

    test('fromMap tolère une candidature sans validation', () {
      final c = Candidature.fromMap(const {
        'id': 'c2',
        'offre_id': 'o1',
        'user_id': 'u1',
        'created_at': '2026-07-01T10:00:00Z',
      });
      expect(c.validations, isEmpty);
    });
  });

  group('ValidationBadge', () {
    testWidgets('affiche le libellé et la date pour une présence',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidationBadge(
              validation: Validation(
                id: 'v1',
                candidatureId: 'c1',
                type: 'presence_evenement',
                scannedAt: DateTime(2026, 8, 1, 10, 30),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Présence validée le 01.08.2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche le libellé pour une confirmation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidationBadge(
              validation: Validation(
                id: 'v2',
                candidatureId: 'c2',
                type: 'confirmation_candidature',
                scannedAt: DateTime(2026, 8, 2),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Candidature confirmée le 02.08.2026'), findsOneWidget);
    });
  });

  group('QR Passeport', () {
    testWidgets('encode le format EFONIJ:<uuid>', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrImageView(
              data: 'EFONIJ:uuid-de-test',
              version: QrVersions.auto,
              size: 120,
            ),
          ),
        ),
      );
      expect(find.byType(QrImageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
