/// Un niveau du Passeport Jeune FONIJ.
class NiveauPasseport {
  const NiveauPasseport({
    required this.numero,
    required this.nom,
    required this.seuilPoints,
    required this.description,
  });

  final int numero;
  final String nom;
  final int seuilPoints;
  final String description;
}

/// Les 4 niveaux du passeport : Graine -> Forêt.
const List<NiveauPasseport> niveauxPasseport = [
  NiveauPasseport(
    numero: 1,
    nom: 'Graine',
    seuilPoints: 150,
    description:
        "L'éveil : on choisit son pilier et on dépose ses premières preuves validées.",
  ),
  NiveauPasseport(
    numero: 2,
    nom: 'Pousse',
    seuilPoints: 400,
    description:
        'Apprenti : on enchaîne les modules et on confirme sa trajectoire dans le pilier.',
  ),
  NiveauPasseport(
    numero: 3,
    nom: 'Arbre',
    seuilPoints: 700,
    description:
        'Bâtisseur : compétences affirmées et impact mesurable sur soi, les autres et la société.',
  ),
  NiveauPasseport(
    numero: 4,
    nom: 'Forêt',
    seuilPoints: 1000,
    description:
        'Ambassadeur : le passeport est délivré et certifié par le FONIJ.',
  ),
];

NiveauPasseport niveauFromNumero(int numero) {
  final clamped = numero.clamp(1, 4);
  return niveauxPasseport[clamped - 1];
}

/// Renvoie le seuil vers lequel le jeune progresse et la progression (0..1).
({int seuil, double progress}) progression(int niveau, int points) {
  if (niveau >= 4) {
    return (seuil: niveauxPasseport[3].seuilPoints, progress: 1.0);
  }
  // Le jeune au niveau N progresse vers le seuil de son niveau actuel :
  // Graine (niveau 1) → 150 pts, Pousse (2) → 400, Arbre (3) → 700.
  final seuil = niveauxPasseport[niveau - 1].seuilPoints;
  final progress = (points / seuil).clamp(0.0, 1.0);
  return (seuil: seuil, progress: progress);
}

/// Pourcentage de progression vers le niveau supérieur, arrondi à 2 décimales.
String pourcentageProgression(int niveau, int points) =>
    (progression(niveau, points).progress * 100).toStringAsFixed(2);

/// Identité imprimée sur le Passeport Jeune (générée de façon déterministe à
/// partir de l'identifiant du compte : identique à chaque affichage).
class IdentitePasseport {
  const IdentitePasseport({
    required this.numero,
    required this.nationalite,
    required this.dateNaissance,
    required this.dateDelivrance,
    required this.dateExpiration,
    required this.sexe,
    required this.mrzLigne1,
    required this.mrzLigne2,
  });

  final String numero;
  final String nationalite;
  final DateTime dateNaissance;
  final DateTime dateDelivrance;
  final DateTime dateExpiration;
  final String sexe;
  final String mrzLigne1;
  final String mrzLigne2;
}

/// Construit l'identité du passeport à partir du profil du jeune.
/// Le n° de passeport et la date de naissance sont dérivés d'un hash stable
/// du userId (identiques à chaque affichage) ; la date de délivrance est
/// quant à elle ancrée dans le passé proche, comme un vrai passeport.
IdentitePasseport identitePasseport({
  required String userId,
  required String prenom,
  required String nom,
}) {
  final seed = _fnv1a(userId);
  var state = seed;
  int next(int max) {
    state = (state * 1664525 + 1013904223) & 0xFFFFFFFF;
    return state % (max < 1 ? 1 : max);
  }

  final alphabet =
      '0123456789ABCDEFGHJKLMNPRSTUVWXYZ'; // sans I, O, Q (ambiguïté)
  final numero =
      String.fromCharCodes(List.generate(9, (_) => alphabet.codeUnitAt(next(alphabet.length))));

  final naissance = DateTime(
    next(10) + 1998, // 1998 → 2007 : profil « jeunes »
    next(12) + 1,
    next(28) + 1,
  );
  // Délivré entre le 1er janvier 2024 et aujourd'hui (jamais dans le futur).
  final aujourdhui = DateTime.now();
  final debutProgramme = DateTime(2024, 1, 1);
  final delivrance = debutProgramme.add(
    Duration(days: next(aujourdhui.difference(debutProgramme).inDays + 1)),
  );
  final expiration = DateTime(delivrance.year + 5, delivrance.month, delivrance.day - 1);

  final surname = _mrz(nom.isNotEmpty ? nom : (prenom.isNotEmpty ? prenom : 'JEUNE'));
  final given = _mrz(prenom);
  final personal = String.fromCharCodes(
    List.generate(9, (_) => alphabet.codeUnitAt(next(alphabet.length))),
  );

  return IdentitePasseport(
    numero: numero,
    nationalite: 'GUINÉENNE',
    dateNaissance: naissance,
    dateDelivrance: delivrance,
    dateExpiration: expiration,
    sexe: 'X', // non renseigné dans le profil
    mrzLigne1: _mrzLigne1(surname: surname, givenNames: given),
    mrzLigne2: _mrzLigne2(
      numero: numero,
      naissance: naissance,
      expiration: expiration,
      personal: personal,
    ),
  );
}

/// Ligne 1 de la zone MRZ : P<GIN + nom + prénoms (44 caractères).
String _mrzLigne1({required String surname, required String givenNames}) {
  final primary = surname.isEmpty ? 'JEUNE' : surname;
  var secondary = givenNames;
  // Si le nom est trop long, on tronque d'abord les prénoms, puis le nom.
  if (primary.length + secondary.length > 39) {
    final over = primary.length + secondary.length - 39;
    secondary = secondary.length > over
        ? secondary.substring(0, secondary.length - over)
        : '';
  }
  final names = '$primary<<$secondary';
  return _pad('P<GIN$names', 44);
}

/// Ligne 2 de la zone MRZ : n° + dates + numéro personnel + chiffres de contrôle.
String _mrzLigne2({
  required String numero,
  required DateTime naissance,
  required DateTime expiration,
  required String personal,
}) {
  final dob = _yymmdd(naissance);
  final exp = _yymmdd(expiration);
  final personalField = _pad(personal, 14);
  final base = '${_pad(numero, 9)}${_checkDigit(numero)}GIN'
      '$dob${_checkDigit(dob)}X$exp${_checkDigit(exp)}$personalField';
  return '$base${_checkDigit(personalField)}${_checkDigit(base + _checkDigit(personalField))}';
}

String _yymmdd(DateTime d) =>
    '${(d.year % 100).toString().padLeft(2, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

/// Normalise un nom pour la MRZ : majuscules, accents retirés, espaces → <.
final _nonMrzChars = RegExp('[^A-Z0-9]');

String _mrz(String s) {
  const map = {
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
    'Ç': 'C',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
    'Ñ': 'N',
    'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
    'Ý': 'Y',
  };
  var out = '';
  for (final ch in s.toUpperCase().split('')) {
    out += map[ch] ?? ch;
  }
  return out.replaceAll(_nonMrzChars, '<');
}

/// Chiffre de contrôle ICAO 9303 (pondérations 7, 3, 1 répétées, mod 10).
String _checkDigit(String s) {
  var sum = 0;
  const weights = [7, 3, 1];
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    final value = (c >= 0x30 && c <= 0x39)
        ? c - 0x30
        : (c >= 0x41 && c <= 0x5A)
            ? c - 0x41 + 10
            : 0; // '<' vaut 0
    sum += value * weights[i % 3];
  }
  return (sum % 10).toString();
}

String _pad(String s, int length) {
  if (s.length >= length) return s.substring(0, length);
  return s.padRight(length, '<');
}

/// Hash FNV-1a 32 bits, stable entre exécutions.
int _fnv1a(String s) {
  var hash = 0x811C9DC5;
  for (final c in s.codeUnits) {
    hash ^= c;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
