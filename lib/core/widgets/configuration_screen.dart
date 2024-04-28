import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Écran affiché quand les credentials Supabase ne sont pas fournis.
class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  'Configuration requise',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Les identifiants Supabase doivent être fournis au lancement, '
                  'jamais codés en dur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B1C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const SelectableText(
                    'flutter run \\\n'
                    '  --dart-define=SUPABASE_URL=https://XXXX.supabase.co \\\n'
                    '  --dart-define=SUPABASE_ANON_KEY=eyJ...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF7EE0A3),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
