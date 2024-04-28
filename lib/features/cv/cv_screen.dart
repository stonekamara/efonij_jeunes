import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../profil/providers/profil_provider.dart';
import 'models/cv.dart';
import 'providers/cv_provider.dart';

/// Écran de création/édition du CV.
class CvScreen extends ConsumerStatefulWidget {
  const CvScreen({super.key});

  @override
  ConsumerState<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends ConsumerState<CvScreen> {
  final _titreController = TextEditingController();
  final _resumeController = TextEditingController();

  final List<CvFormation> _formations = [];
  final List<CvExperience> _experiences = [];
  final List<CvCompetence> _competences = [];
  final List<CvLangue> _langues = [];

  final _competenceController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cv = await ref.read(cvProvider.future);
    if (!mounted) return;
    setState(() {
      _titreController.text = cv?.titrePoste ?? '';
      _resumeController.text = cv?.resume ?? '';
      _formations
        ..clear()
        ..addAll(cv?.formations ?? const []);
      _experiences
        ..clear()
        ..addAll(cv?.experiences ?? const []);
      _competences
        ..clear()
        ..addAll(cv?.competences ?? const []);
      _langues
        ..clear()
        ..addAll(cv?.langues ?? const []);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final profile = await ref.read(profilProvider.future);
      final cv = Cv(
        userId: profile.id,
        titrePoste: _titreController.text.trim().isEmpty
            ? null
            : _titreController.text.trim(),
        resume: _resumeController.text.trim().isEmpty
            ? null
            : _resumeController.text.trim(),
        formations: List.of(_formations),
        experiences: List.of(_experiences),
        competences: _competences.where((c) => c.nom.trim().isNotEmpty).toList(),
        langues: _langues.where((l) => l.langue.trim().isNotEmpty).toList(),
      );
      await ref.read(cvRepositoryProvider).sauvegarder(cv);
      ref.invalidate(cvProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV enregistré ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _resumeController.dispose();
    _competenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon CV'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const _IntroCard(),
                const SizedBox(height: 12),
                _ResumeCard(
                  titreController: _titreController,
                  resumeController: _resumeController,
                ),
                const SizedBox(height: 12),
                _FormationsCard(
                  formations: _formations,
                  onAdd: () => setState(() =>
                      _formations.add(const CvFormation(diplome: ''))),
                  onChanged: (index, value) =>
                      setState(() => _formations[index] = value),
                  onDelete: (index) =>
                      setState(() => _formations.removeAt(index)),
                ),
                const SizedBox(height: 12),
                _ExperiencesCard(
                  experiences: _experiences,
                  onAdd: () => setState(() =>
                      _experiences.add(const CvExperience(poste: ''))),
                  onChanged: (index, value) =>
                      setState(() => _experiences[index] = value),
                  onDelete: (index) =>
                      setState(() => _experiences.removeAt(index)),
                ),
                const SizedBox(height: 12),
                _CompetencesCard(
                  competences: _competences,
                  controller: _competenceController,
                  onAdd: () {
                    final nom = _competenceController.text.trim();
                    if (nom.isEmpty) return;
                    setState(() {
                      _competences.add(CvCompetence(nom: nom));
                      _competenceController.clear();
                    });
                  },
                  onDelete: (index) =>
                      setState(() => _competences.removeAt(index)),
                ),
                const SizedBox(height: 12),
                _LanguesCard(
                  langues: _langues,
                  onAdd: () => setState(
                      () => _langues.add(const CvLangue(langue: ''))),
                  onChanged: (index, value) =>
                      setState(() => _langues[index] = value),
                  onDelete: (index) =>
                      setState(() => _langues.removeAt(index)),
                ),
              ],
            ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ce CV est joint automatiquement à chacune de tes candidatures. '
                'Complète au moins le résumé ou une formation pour pouvoir postuler.',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.titreController, required this.resumeController});

  final TextEditingController titreController;
  final TextEditingController resumeController;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Résumé',
      icon: Icons.person_outline,
      child: Column(
        children: [
          TextField(
            controller: titreController,
            decoration: const InputDecoration(
              labelText: 'Titre du poste visé',
              hintText: 'Ex. Développeur junior',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: resumeController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Résumé',
              hintText: '2-3 phrases sur ton parcours et tes objectifs…',
            ),
          ),
        ],
      ),
    );
  }
}

class _FormationsCard extends StatelessWidget {
  const _FormationsCard({
    required this.formations,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
  });

  final List<CvFormation> formations;
  final VoidCallback onAdd;
  final void Function(int, CvFormation) onChanged;
  final void Function(int) onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Formations',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          if (formations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune formation ajoutée.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          for (var i = 0; i < formations.length; i++)
            _FormationTile(
              index: i,
              initial: formations[i],
              onChanged: (f) => onChanged(i, f),
              onDelete: () => onDelete(i),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une formation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormationTile extends StatefulWidget {
  const _FormationTile({
    required this.index,
    required this.initial,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final CvFormation initial;
  final void Function(CvFormation) onChanged;
  final VoidCallback onDelete;

  @override
  State<_FormationTile> createState() => _FormationTileState();
}

class _FormationTileState extends State<_FormationTile> {
  late final _diplome = TextEditingController(text: widget.initial.diplome);
  late final _etablissement =
      TextEditingController(text: widget.initial.etablissement ?? '');
  late final _anneeDebut =
      TextEditingController(text: widget.initial.anneeDebut?.toString() ?? '');
  late final _anneeFin =
      TextEditingController(text: widget.initial.anneeFin?.toString() ?? '');

  void _emit() {
    widget.onChanged(CvFormation(
      diplome: _diplome.text.trim(),
      etablissement: _etablissement.text.trim().isEmpty
          ? null
          : _etablissement.text.trim(),
      anneeDebut: int.tryParse(_anneeDebut.text),
      anneeFin: int.tryParse(_anneeFin.text),
    ));
  }

  @override
  void dispose() {
    _diplome.dispose();
    _etablissement.dispose();
    _anneeDebut.dispose();
    _anneeFin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _diplome,
                  onChanged: (_) => _emit(),
                  decoration: const InputDecoration(labelText: 'Diplôme *'),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _etablissement,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(labelText: 'Établissement'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _anneeDebut,
                  onChanged: (_) => _emit(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  decoration: const InputDecoration(labelText: 'Année début'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _anneeFin,
                  onChanged: (_) => _emit(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  decoration: const InputDecoration(labelText: 'Année fin'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExperiencesCard extends StatelessWidget {
  const _ExperiencesCard({
    required this.experiences,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
  });

  final List<CvExperience> experiences;
  final VoidCallback onAdd;
  final void Function(int, CvExperience) onChanged;
  final void Function(int) onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Expériences',
      icon: Icons.work_outline,
      child: Column(
        children: [
          if (experiences.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune expérience ajoutée.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          for (var i = 0; i < experiences.length; i++)
            _ExperienceTile(
              index: i,
              initial: experiences[i],
              onChanged: (e) => onChanged(i, e),
              onDelete: () => onDelete(i),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une expérience'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceTile extends StatefulWidget {
  const _ExperienceTile({
    required this.index,
    required this.initial,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final CvExperience initial;
  final void Function(CvExperience) onChanged;
  final VoidCallback onDelete;

  @override
  State<_ExperienceTile> createState() => _ExperienceTileState();
}

class _ExperienceTileState extends State<_ExperienceTile> {
  late final _poste = TextEditingController(text: widget.initial.poste);
  late final _organisation =
      TextEditingController(text: widget.initial.organisation ?? '');
  late final _dateDebut = TextEditingController(
      text: widget.initial.dateDebut?.toIso8601String().split('T').first ?? '');
  late final _dateFin = TextEditingController(
      text: widget.initial.dateFin?.toIso8601String().split('T').first ?? '');
  late final _description =
      TextEditingController(text: widget.initial.description ?? '');

  void _emit() {
    widget.onChanged(CvExperience(
      poste: _poste.text.trim(),
      organisation: _organisation.text.trim().isEmpty
          ? null
          : _organisation.text.trim(),
      dateDebut: DateTime.tryParse(_dateDebut.text),
      dateFin: DateTime.tryParse(_dateFin.text),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
    ));
  }

  @override
  void dispose() {
    _poste.dispose();
    _organisation.dispose();
    _dateDebut.dispose();
    _dateFin.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _poste,
                  onChanged: (_) => _emit(),
                  decoration: const InputDecoration(labelText: 'Poste *'),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _organisation,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(labelText: 'Organisation'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateDebut,
                  onChanged: (_) => _emit(),
                  decoration: const InputDecoration(
                    labelText: 'Date début',
                    hintText: 'AAAA-MM-JJ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dateFin,
                  onChanged: (_) => _emit(),
                  decoration: const InputDecoration(
                    labelText: 'Date fin',
                    hintText: 'AAAA-MM-JJ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            onChanged: (_) => _emit(),
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
    );
  }
}

class _CompetencesCard extends StatelessWidget {
  const _CompetencesCard({
    required this.competences,
    required this.controller,
    required this.onAdd,
    required this.onDelete,
  });

  final List<CvCompetence> competences;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(int) onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Compétences',
      icon: Icons.build_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  decoration: const InputDecoration(
                    labelText: 'Ajouter une compétence',
                    hintText: 'Ex. Flutter, Excel, travail en équipe…',
                  ),
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                tooltip: 'Ajouter',
              ),
            ],
          ),
          if (competences.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune compétence ajoutée.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < competences.length; i++)
                  InputChip(
                    label: Text(competences[i].nom),
                    onDeleted: () => onDelete(i),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    deleteIconColor: AppColors.primary,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LanguesCard extends StatelessWidget {
  const _LanguesCard({
    required this.langues,
    required this.onAdd,
    required this.onChanged,
    required this.onDelete,
  });

  final List<CvLangue> langues;
  final VoidCallback onAdd;
  final void Function(int, CvLangue) onChanged;
  final void Function(int) onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Langues',
      icon: Icons.language,
      child: Column(
        children: [
          if (langues.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune langue ajoutée.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          for (var i = 0; i < langues.length; i++)
            _LangueTile(
              index: i,
              initial: langues[i],
              onChanged: (l) => onChanged(i, l),
              onDelete: () => onDelete(i),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une langue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangueTile extends StatefulWidget {
  const _LangueTile({
    required this.index,
    required this.initial,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final CvLangue initial;
  final void Function(CvLangue) onChanged;
  final VoidCallback onDelete;

  @override
  State<_LangueTile> createState() => _LangueTileState();
}

class _LangueTileState extends State<_LangueTile> {
  static const niveaux = [
    'debutant',
    'intermediaire',
    'courant',
    'bilingue',
  ];

  late final _langue =
      TextEditingController(text: widget.initial.langue);
  late String? _niveau = widget.initial.niveau;

  void _emit() {
    widget.onChanged(CvLangue(langue: _langue.text.trim(), niveau: _niveau));
  }

  @override
  void dispose() {
    _langue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _langue,
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(labelText: 'Langue *'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Niveau'),
              child: DropdownButton<String>(
                value: _niveau,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('—'),
                items: [
                  for (final n in niveaux)
                    DropdownMenuItem(value: n, child: Text(niveauLabel(n))),
                ],
                onChanged: (v) => setState(() {
                  _niveau = v;
                  _emit();
                }),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

