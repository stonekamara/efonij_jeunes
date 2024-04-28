import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/piliers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offre_card.dart';
import '../providers/offres_controller.dart';

class OffresScreen extends ConsumerStatefulWidget {
  const OffresScreen({super.key});

  @override
  ConsumerState<OffresScreen> createState() => _OffresScreenState();
}

class _OffresScreenState extends ConsumerState<OffresScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offresControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(offresControllerProvider.notifier).loadMore();
    }
  }

  void _openFilters() {
    final state = ref.read(offresControllerProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _FiltersSheet(
        initialType: state.typeFilter,
        initialPilier: state.pilierFilter,
        onApply: (type, pilier) {
          ref.read(offresControllerProvider.notifier).setFilters(
                type: type,
                pilier: pilier,
              );
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offresControllerProvider);
    final controller = ref.read(offresControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offres'),
        actions: [
          IconButton(
            onPressed: _openFilters,
            tooltip: 'Filtrer',
            icon: Badge(
              isLabelVisible: state.hasActiveFilters,
              backgroundColor: AppColors.accent,
              label: const Text('•'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.hasActiveFilters)
            _ActiveFiltersBar(
              type: state.typeFilter,
              pilier: state.pilierFilter,
              onClear: controller.clearFilters,
            ),
          Expanded(
            child: state.isLoading && state.offres.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.offres.isEmpty
                    ? _ErrorView(
                        error: state.error!,
                        onRetry: controller.refresh,
                      )
                    : RefreshIndicator(
                        onRefresh: controller.refresh,
                        child: state.offres.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 160),
                                  EmptyState(
                                    icon: Icons.work_off,
                                    title: 'Aucune offre trouvée',
                                    message:
                                        'Modifiez vos filtres ou revenez plus tard.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    state.offres.length + (state.hasMore ? 1 : 0),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= state.offres.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final offre = state.offres[index];
                                  return OffreCard(
                                    offre: offre,
                                    onTap: () => context.push(
                                      '/offres/${offre.id}',
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.type,
    required this.pilier,
    required this.onClear,
  });

  final String? type;
  final String? pilier;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: [
                if (type != null)
                  Chip(
                    label: Text(typeLabel(type!)),
                    onDeleted: onClear,
                    visualDensity: VisualDensity.compact,
                  ),
                if (pilier != null)
                  Chip(
                    label: Text('Pilier $pilier'),
                    onDeleted: onClear,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.initialType,
    required this.initialPilier,
    required this.onApply,
  });

  final String? initialType;
  final String? initialPilier;
  final void Function(String? type, String? pilier) onApply;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  static const _types = ['formation', 'stage', 'emploi', 'concours', 'bootcamp'];

  late String? _type;
  late String? _pilier;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _pilier = widget.initialPilier;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtrer les offres', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _types)
                ChoiceChip(
                  label: Text(typeLabel(type)),
                  selected: _type == type,
                  onSelected: (selected) =>
                      setState(() => _type = selected ? type : null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Pilier', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pilier in piliers)
                ChoiceChip(
                  label: Text(pilier.code),
                  avatar: Icon(pilier.icon, size: 16, color: pilier.color),
                  selected: _pilier == pilier.code,
                  onSelected: (selected) => setState(
                      () => _pilier = selected ? pilier.code : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onApply(null, null),
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onApply(_type, _pilier),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger les offres',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

