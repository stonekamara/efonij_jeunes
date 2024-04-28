import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Une notification in-app destinée à un jeune.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.titre,
    required this.type,
    required this.lu,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String titre;
  final String? message;
  final String type;
  final bool lu;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      titre: map['titre'] as String? ?? '',
      message: map['message'] as String?,
      type: map['type'] as String? ?? 'info',
      lu: map['lu'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  AppNotification marqueLue() => AppNotification(
        id: id,
        titre: titre,
        message: message,
        type: type,
        lu: true,
        createdAt: createdAt,
      );

  /// Icône et couleur associées au type de notification.
  (IconData, Color) get visual =>
      switch (type) {
        'candidature' => (Icons.assignment_outlined, AppColors.pilierEd),
        'validation' => (Icons.verified_outlined, AppColors.success),
        'offre' => (Icons.work_outline, AppColors.pilierIt),
        'admin' => (Icons.campaign_outlined, AppColors.accent),
        _ => (Icons.info_outline, AppColors.textSecondary),
      };
}
