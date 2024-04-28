import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduit une erreur d'authentification en message français lisible.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('email not confirmed')) {
      return 'Veuillez confirmer votre adresse email avant de vous connecter.';
    }
    if (message.contains('already registered') ||
        message.contains('user already exists')) {
      return 'Un compte existe déjà avec cette adresse email.';
    }
    if (message.contains('password should be at least') ||
        message.contains('weak password')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (error.statusCode?.toString() == '429') {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    return 'Erreur : ${error.message}';
  }
  return 'Une erreur est survenue. Veuillez réessayer.';
}
