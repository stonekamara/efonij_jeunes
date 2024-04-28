import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/app_notification.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> items;
  final bool isLoading;
  final Object? error;

  int get unread => items.where((n) => !n.lu).length;

  NotificationsState copyWith({
    List<AppNotification>? items,
    bool? isLoading,
    Object? error,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);

/// Nombre de notifications non lues (badge sur l'accueil).
final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).unread,
);

/// Notifications in-app : chargement initial + réception temps réel via
/// Supabase Realtime (une notification envoyée par le back-office apparaît
/// immédiatement, sans relancer l'app).
class NotificationsController extends Notifier<NotificationsState> {
  RealtimeChannel? _channel;
  String? _subscribedUserId;

  @override
  NotificationsState build() {
    // Reconstruit l'état quand l'authentification change (login/logout).
    ref.watch(authRefreshProvider);

    state = const NotificationsState(isLoading: true);
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      unawaited(_load());
      _subscribe(userId);
    }
    ref.onDispose(() => _channel?.unsubscribe());
    return state;
  }

  Future<void> _load() async {
    try {
      final rows = await supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      state = state.copyWith(
        items: rows.map(AppNotification.fromMap).toList(),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void _subscribe(String userId) {
    // Ré-abonne si l'utilisateur change (logout puis login d'un autre compte).
    if (_subscribedUserId == userId) return;
    if (_channel != null) {
      _channel!.unsubscribe();
      _channel = null;
    }
    _subscribedUserId = userId;
    _channel = supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: _onChange,
        )
        .subscribe();
  }

  void _onChange(PostgresChangePayload payload) {
    final newRecord = payload.newRecord as Map<String, dynamic>?;
    if (payload.eventType == PostgresChangeEvent.insert && newRecord != null) {
      state = state.copyWith(
        items: [AppNotification.fromMap(newRecord), ...state.items],
      );
    } else if (payload.eventType == PostgresChangeEvent.update &&
        newRecord != null) {
      final updated = AppNotification.fromMap(newRecord);
      state = state.copyWith(
        items: [
          for (final n in state.items) n.id == updated.id ? updated : n,
        ],
      );
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'] as String?;
      if (id != null) {
        state = state.copyWith(
          items: [
            for (final n in state.items)
              if (n.id != id) n,
          ],
        );
      }
    }
  }

  /// Marque une notification comme lue (mise à jour optimiste + serveur).
  Future<void> marquerLue(String id) async {
    if (state.items.any((n) => n.id == id && !n.lu)) {
      state = state.copyWith(
        items: [
          for (final n in state.items) n.id == id ? n.marqueLue() : n,
        ],
      );
    }
    try {
      await supabase.from('notifications').update({'lu': true}).eq('id', id);
    } catch (_) {
      // Silencieux : la prochaine synchronisation rétablira l'état.
    }
  }

  Future<void> toutMarquerLue() async {
    final nonLues = state.items.where((n) => !n.lu).map((n) => n.id).toList();
    if (nonLues.isEmpty) return;
    state = state.copyWith(
      items: [for (final n in state.items) if (!n.lu) n.marqueLue() else n],
    );
    try {
      await supabase
          .from('notifications')
          .update({'lu': true})
          .inFilter('id', nonLues);
    } catch (_) {
      // Silencieux.
    }
  }

  /// Supprime une notification (suppression optimiste + serveur).
  Future<void> supprimer(String id) async {
    state = state.copyWith(
      items: [for (final n in state.items) if (n.id != id) n],
    );
    try {
      await supabase.from('notifications').delete().eq('id', id);
    } catch (_) {
      // Silencieux : la prochaine synchronisation rétablira l'état.
    }
  }

  /// Supprime toutes les notifications de l'utilisateur.
  Future<void> toutSupprimer() async {
    if (state.items.isEmpty) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = state.copyWith(items: const []);
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (_) {
      // Silencieux : la prochaine synchronisation rétablira l'état.
    }
  }
}
