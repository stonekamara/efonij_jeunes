import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Un pilier SIMANDOU 2040.
class Pilier {
  const Pilier({
    required this.code,
    required this.nom,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String code;
  final String nom;
  final String description;
  final IconData icon;
  final Color color;

  static Pilier? fromCode(String? code) {
    if (code == null) return null;
    for (final pilier in piliers) {
      if (pilier.code == code) return pilier;
    }
    return null;
  }
}

const List<Pilier> piliers = [
  Pilier(
    code: 'AG',
    nom: 'Agriculture, industrie alimentaire & commerce',
    description:
        'Cultiver, transformer et commercialiser les richesses agricoles de la Guinée.',
    icon: Icons.agriculture,
    color: AppColors.pilierAg,
  ),
  Pilier(
    code: 'ED',
    nom: 'Éducation & culture',
    description:
        'Transmettre les savoirs, la culture et les savoir-faire aux générations de demain.',
    icon: Icons.school,
    color: AppColors.pilierEd,
  ),
  Pilier(
    code: 'IT',
    nom: 'Infrastructures, transports & technologies',
    description:
        'Bâtir et connecter : routes, énergie, numérique et innovations techniques.',
    icon: Icons.engineering,
    color: AppColors.pilierIt,
  ),
  Pilier(
    code: 'EC',
    nom: 'Économie, finance & assurances',
    description:
        'Financer les projets, sécuriser les risques et faire grandir l’économie nationale.',
    icon: Icons.account_balance,
    color: AppColors.pilierEc,
  ),
  Pilier(
    code: 'SA',
    nom: 'Santé & bien-être',
    description:
        'Soigner, prévenir et promouvoir le bien-être de chaque citoyen.',
    icon: Icons.health_and_safety,
    color: AppColors.pilierSa,
  ),
];
