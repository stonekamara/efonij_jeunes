import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/piliers.dart';
import '../../core/theme/app_theme.dart';
import 'passeport_service.dart';

/// Passeport Jeune FONIJ affiché en style « carte bancaire » (ratio ISO 7810,
/// 85,6 × 53,98 mm) : le format unique du Passeport Jeune.
///
/// Deux faces avec retournement animé au toucher (version pleine) :
/// - Face avant : logo, symbole sans-contact, numéro (matricule unique),
///   titulaire, validité, niveau et pilier.
/// - Face arrière : bande magnétique, bande de signature et QR code agrandi,
///   scannable par les partenaires.
class CarteFonijCard extends StatefulWidget {
  const CarteFonijCard({
    super.key,
    required this.niveau,
    required this.pilierCode,
    this.userId,
    this.prenom,
    this.nom,
    this.matricule,
    this.region,
    this.points,
    this.onTap,
    this.compact = false,
  });

  final int niveau;
  final String? pilierCode;
  final String? userId;
  final String? prenom;
  final String? nom;
  final String? matricule;
  final String? region;
  final int? points;

  /// Action externe (ex. navigation) ; la version compacte (accueil / profil)
  /// ne se retourne pas et utilise [onTap] à la place.
  final VoidCallback? onTap;

  /// Variante réduite pour l'accueil et le profil (sans QR ni retournement).
  final bool compact;

  @override
  State<CarteFonijCard> createState() => _CarteFonijCardState();
}

class _CarteFonijCardState extends State<CarteFonijCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _flipAnim =
      CurvedAnimation(parent: _flip, curve: Curves.easeInOut);

  bool get _flippable => widget.onTap == null && !widget.compact;

  void _toggleFlip() {
    if (!_flippable) return;
    if (_flip.isCompleted) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = niveauFromNumero(widget.niveau);
    final pilier = Pilier.fromCode(widget.pilierCode);
    final hasIdentite = widget.userId != null && widget.userId!.isNotEmpty;
    final identite = hasIdentite
        ? identitePasseport(
            userId: widget.userId!,
            prenom: widget.prenom ?? '',
            nom: widget.nom ?? '',
          )
        : null;

    final prenomDisplay = (widget.prenom ?? '').isNotEmpty ? widget.prenom! : 'JEUNE';
    final nomDisplay = (widget.nom ?? '').isNotEmpty ? widget.nom! : 'FONIJ';
    final numeroCarte = _formatMatricule(widget.matricule) ??
        (hasIdentite ? _numeroCarte(widget.userId!) : 'FONIJ -- ------');
    final validThru = identite != null
        ? '${identite.dateExpiration.month.toString().padLeft(2, '0')}'
            '/${(identite.dateExpiration.year % 100).toString().padLeft(2, '0')}'
        : '--/--';

    final card = AnimatedBuilder(
      animation: _flipAnim,
      builder: (context, _) {
        final angle = _flipAnim.value * math.pi;
        final showBack = angle > math.pi / 2;
        return Semantics(
          button: _flippable,
          label: _flippable ? 'Retourner la carte' : null,
          child: GestureDetector(
          onTap: _flippable
              ? _toggleFlip
              : widget.onTap,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBack(
                      prenomDisplay: prenomDisplay,
                      nomDisplay: nomDisplay,
                      hasIdentite: hasIdentite,
                    ),
                  )
                : _buildFront(
                    niveau: widget.niveau,
                    pilier: pilier,
                    level: level,
                    numeroCarte: numeroCarte,
                    validThru: validThru,
                    prenomDisplay: prenomDisplay,
                    nomDisplay: nomDisplay,
                    points: widget.points,
                  ),
          ),
        ),
        );
      },
    );

    return card;
  }

  // ---------------------------------------------------------------------------
  // Face avant
  // ---------------------------------------------------------------------------

  Widget _buildFront({
    required int niveau,
    required Pilier? pilier,
    required NiveauPasseport level,
    required String numeroCarte,
    required String validThru,
    required String prenomDisplay,
    required String nomDisplay,
    int? points,
  }) {
    final compact = widget.compact;
    // En version compacte on n'affiche que le nombre de points (discret),
    // en version pleine on ajoute le pourcentage de progression arrondi.
    final pourcent = (points != null && !compact)
        ? pourcentageProgression(niveau, points)
        : null; // String? (ex. « 38.75 ») ou null en compacte.
    return AspectRatio(
      aspectRatio: 85.6 / 53.98,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            ..._glowCircles(),
            Padding(
              padding: EdgeInsets.all(compact ? 14 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LogoBox(size: compact ? 26 : 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'E-FONIJ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 13 : 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'PASSEPORT JEUNE',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.nfc,
                        color: Colors.white70,
                        size: compact ? 22 : 26,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    numeroCarte,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: compact ? 13 : 15,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _CardField(
                          label: 'Titulaire',
                          value: '$nomDisplay $prenomDisplay'.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CardField(label: 'Validité', value: validThru),
                      const SizedBox(width: 12),
                      _CardField(
                        label: 'Niveau',
                        value: '$niveau · ${level.nom.toUpperCase()}',
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PilierBadge(pilier: pilier),
                              if (points != null) ...[const SizedBox(width: 6), _PointsBadge(points: points, pourcent: pourcent)],
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_flippable) const _FlipHint(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Face arrière (bande magnétique + signature + QR agrandi)
  // ---------------------------------------------------------------------------

  Widget _buildBack({
    required String prenomDisplay,
    required String nomDisplay,
    required bool hasIdentite,
  }) {
    return AspectRatio(
      aspectRatio: 85.6 / 53.98,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            ..._glowCircles(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bande magnétique.
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14181A),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bande de signature + QR agrandi.
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F5F4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SIGNATURE',
                                  style: TextStyle(
                                    color: Color(0xFF6B7A7B),
                                    fontSize: 8,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                      '$nomDisplay $prenomDisplay',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2B4A4C),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.matricule != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.matricule!,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7A7B),
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // QR agrandi, scannable par les partenaires (adaptatif
                        // pour éviter tout débordement sur écran étroit).
                        FittedBox(
                          fit: BoxFit.contain,
                          child: Container(
                            width: 108,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: hasIdentite
                                ? QrImageView(
                                    data: 'EFONIJ:${widget.userId}',
                                    version: QrVersions.auto,
                                    size: 90,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF0A4449),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF0A4449),
                                    ),
                                  )
                                : const Icon(
                                    Icons.qr_code_2,
                                    size: 44,
                                    color: Color(0xFF0A4449),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.nfc, size: 16, color: Colors.white54),
                      SizedBox(width: 6),
                      Text(
                        'SANS CONTACT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'E-FONIJ · PASSEPORT JEUNE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Habillage commun
  // ---------------------------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A4449), AppColors.primary, Color(0xFF2E8A93)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.35),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  List<Widget> _glowCircles() {
    return const [
      Positioned(
        top: -70,
        right: -40,
        child: _GlowCircle(size: 190, opacity: 0.10),
      ),
      Positioned(
        bottom: -90,
        left: -50,
        child: _GlowCircle(size: 210, opacity: 0.08),
      ),
    ];
  }
}

/// Indicateur « touchez pour retourner » sur la face avant.
class _FlipHint extends StatelessWidget {
  const _FlipHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flip, size: 13, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Touchez pour retourner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge pilier de la carte.
class _PilierBadge extends StatelessWidget {
  const _PilierBadge({this.pilier});

  final Pilier? pilier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pilier?.icon ?? Icons.eco, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            pilier?.code ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge « points » de la carte : solde + pourcentage de progression arrondi.
class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points, this.pourcent});

  final int points;
  final String? pourcent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, size: 12, color: AppColors.textPrimary),
          const SizedBox(width: 5),
          Text(
            pourcent == null ? '$points pts' : '$points pts · $pourcent%',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit carré logo (fond assorti au logo réel pour un rendu sans couture).
class _LogoBox extends StatelessWidget {
  const _LogoBox({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Image.asset(
        'assets/images/logo_efonij.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Cercle décoratif translucide.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Libellé + valeur sur la carte (petit, espacé).
class _CardField extends StatelessWidget {
  const _CardField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 7,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Met le matricule en forme de numéro de carte : FONIJ-26-000123 →
/// « FONIJ 26 000123 ».
String? _formatMatricule(String? matricule) {
  if (matricule == null || matricule.isEmpty) return null;
  final parts = matricule.split('-');
  if (parts.length == 3) return '${parts[0]} ${parts[1]} ${parts[2]}';
  return matricule;
}

/// Numéro de carte 16 chiffres de secours (déterministe par utilisateur),
/// utilisé uniquement si le matricule n'est pas encore disponible.
String _numeroCarte(String userId) {
  var h = 0x811C9DC5;
  for (final c in userId.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  final sb = StringBuffer();
  for (var i = 0; i < 16; i++) {
    h = (h * 1664525 + 1013904223) & 0xFFFFFFFF;
    sb.write((h >> 16) % 10);
  }
  final s = sb.toString();
  return '${s.substring(0, 4)} ${s.substring(4, 8)} '
      '${s.substring(8, 12)} ${s.substring(12)}';
}
