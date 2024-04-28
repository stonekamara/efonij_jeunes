import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../auth/providers/auth_controller.dart';
import '../data/profil_repository.dart';
import '../models/profile.dart';
import '../providers/profil_provider.dart';

class EditProfilScreen extends ConsumerStatefulWidget {
  const EditProfilScreen({super.key});

  @override
  ConsumerState<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends ConsumerState<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _regionController = TextEditingController();
  final _telephoneController = TextEditingController();

  XFile? _pendingAvatar;
  Uint8List? _pendingAvatarBytes;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _regionController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _ensureInitialized(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _prenomController.text = profile.prenom;
    _nomController.text = profile.nom;
    _regionController.text = profile.region ?? '';
    _telephoneController.text = profile.telephone ?? '';
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingAvatar = file;
        _pendingAvatarBytes = bytes;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de sélectionner une image.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _save(Profile profile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? avatarUrl = profile.avatarUrl;
      final avatar = _pendingAvatar;
      if (avatar != null) {
        final extension = avatar.name.contains('.')
            ? avatar.name.split('.').last.toLowerCase()
            : 'jpg';
        avatarUrl = await ref.read(profilRepositoryProvider).uploadAvatar(
              profile.id,
              _pendingAvatarBytes ?? Uint8List(0),
              extension: extension,
              contentType: avatar.mimeType,
            );
      }
      await ref.read(profilRepositoryProvider).updateProfile(profile.id, {
        'prenom': _prenomController.text.trim(),
        'nom': _nomController.text.trim(),
        'region': _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
        'telephone': _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        'avatar_url': avatarUrl,
      });
      ref.invalidate(profilProvider);
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour ✓')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Impossible de charger le profil : $e'),
        ),
        data: (profile) {
          _ensureInitialized(profile);
          final bytes = _pendingAvatarBytes;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            children: [
                              if (bytes != null)
                                ClipOval(
                                  child: Image.memory(
                                    bytes,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                AvatarView(
                                  url: profile.avatarUrl,
                                  prenom: profile.prenom,
                                  nom: profile.nom,
                                  size: 100,
                                ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Toucher pour changer la photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _prenomController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Prénom requis'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Nom requis'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regionController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Région',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(profile),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
