-- ============================================================================
-- eFonij — Migration 0007 : Suppression des notifications
-- ----------------------------------------------------------------------------
-- Permet à un jeune de supprimer SES notifications, et à l'admin FONIJ
-- d'en supprimer n'importe laquelle (modération / nettoyage).
-- ============================================================================

-- Un jeune supprime ses propres notifications.
create policy "jeune supprime ses notifications" on notifications
  for delete using (auth.uid() = user_id);

-- L'admin FONIJ (back-office) peut supprimer n'importe quelle notification.
create policy "admin fonij supprime les notifications" on notifications
  for delete using (public.is_fonij_admin());
