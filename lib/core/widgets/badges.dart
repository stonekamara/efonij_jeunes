import 'package:flutter/material.dart';

import '../constants/piliers.dart';
import '../theme/app_theme.dart';
import '../utils/labels.dart';

/// Badge pilier SIMANDOU (AG, ED, IT, EC, SA).
class PilierBadge extends StatelessWidget {
  const PilierBadge({super.key, this.code, this.compact = false});

  final String? code;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pilier = Pilier.fromCode(code);
    if (pilier == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: pilier.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pilier.icon, size: compact ? 12 : 14, color: pilier.color),
          const SizedBox(width: 4),
          Text(
            pilier.code,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: pilier.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge type d'offre (formation, stage, emploi, concours, bootcamp).
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final String type;

  Color get _color {
    switch (type) {
      case 'formation':
        return AppColors.pilierEd;
      case 'stage':
        return AppColors.primary;
      case 'emploi':
        return AppColors.success;
      case 'concours':
        return AppColors.pilierEc;
      case 'bootcamp':
        return AppColors.pilierIt;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        typeLabel(type),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

/// Badge statut de candidature (en attente / acceptée / refusée).
class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut});

  final String statut;

  Color get _color {
    switch (statut) {
      case 'en_attente':
        return AppColors.pilierEc;
      case 'acceptee':
        return AppColors.success;
      case 'refusee':
        return AppColors.danger;
      default:
        return AppColors.pilierEd;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statutLabel(statut),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
