import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Avatar : image réseau mise en cache, sinon initiales.
/// Cercle par défaut ; passer [radius] pour un avatar arrondi/rectangulaire
/// (ex. photo d'identité du passeport).
class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    this.url,
    required this.prenom,
    required this.nom,
    this.size = 40,
    this.radius,
  });

  final String? url;
  final String prenom;
  final String nom;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final initials = ((prenom.isNotEmpty ? prenom[0] : '') +
            (nom.isNotEmpty ? nom[0] : ''))
        .toUpperCase();
    final rounded = radius != null;

    Widget image() {
      final cached = CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _Placeholder(size: size),
        errorWidget: (_, _, _) =>
            _Initials(initials: initials, size: size, radius: radius),
      );
      if (rounded) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius!),
          child: cached,
        );
      }
      return ClipOval(child: cached);
    }

    if (url != null && url!.isNotEmpty) return image();
    return _Initials(initials: initials, size: size, radius: radius);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: size * 0.5, color: AppColors.primary),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size, this.radius});

  final String initials;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius == null ? null : BorderRadius.circular(radius!),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E8A93)],
        ),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
