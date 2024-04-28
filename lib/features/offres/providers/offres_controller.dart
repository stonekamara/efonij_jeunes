import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/offre.dart';
import '../../../core/services/supabase_client.dart';

class OffresState {
  const OffresState({
    this.offres = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.typeFilter,
    this.pilierFilter,
  });

  final List<Offre> offres;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final String? typeFilter;
  final String? pilierFilter;

  bool get hasActiveFilters => typeFilter != null || pilierFilter != null;

  OffresState copyWith({
    List<Offre>? offres,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    String? typeFilter,
    String? pilierFilter,
  }) {
    return OffresState(
      offres: offres ?? this.offres,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      typeFilter: typeFilter ?? this.typeFilter,
      pilierFilter: pilierFilter ?? this.pilierFilter,
    );
  }
}

final offresControllerProvider =
    NotifierProvider<OffresController, OffresState>(OffresController.new);

/// Liste des offres : filtres par type/pilier, pull-to-refresh, pagination.
class OffresController extends Notifier<OffresState> {
  static const int pageSize = 20;

  @override
  OffresState build() => const OffresState();

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null, offres: const []);
    try {
      await _fetchPage(0, reset: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      await _fetchPage(state.page + 1, reset: false);
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _fetchPage(int page, {required bool reset}) async {
    final type = state.typeFilter;
    final pilier = state.pilierFilter;

    var filter = supabase.from('offres').select('*, organisations(nom)');
    if (type != null) filter = filter.eq('type', type);
    if (pilier != null) filter = filter.eq('pilier', pilier);
    final rows = await filter
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize - 1);
    final items = rows.map(Offre.fromMap).toList();

    state = state.copyWith(
      offres: reset ? items : [...state.offres, ...items],
      page: page,
      hasMore: items.length == pageSize,
      isLoading: false,
      isLoadingMore: false,
    );
  }

  void setFilters({String? type, String? pilier}) {
    // Construit un nouvel état : passer null doit bien effacer le filtre
    // (contrairement à copyWith qui conserverait l'ancienne valeur).
    state = OffresState(typeFilter: type, pilierFilter: pilier);
    refresh();
  }

  void clearFilters() => setFilters(type: null, pilier: null);
}
