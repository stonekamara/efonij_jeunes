-- ============================================================================
-- eFonij — Migration 0004 : Notifications in-app
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Table notifications (une ligne = un message pour un jeune)
-- ---------------------------------------------------------------------------

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  titre text not null,
  message text,
  type text not null default 'info'
    check (type in ('info', 'candidature', 'validation', 'offre', 'admin')),
  lu boolean not null default false,
  envoyee_par uuid references auth.users(id),
  created_at timestamptz default now()
);

create index notifications_user_created_idx
  on notifications (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 2. Row Level Security
-- ---------------------------------------------------------------------------

alter table notifications enable row level security;

-- Un jeune lit et marque comme lues SES notifications.
create policy "jeune lit ses notifications" on notifications
  for select using (auth.uid() = user_id);

create policy "jeune marque ses notifications lues" on notifications
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Seul l'admin FONIJ peut créer des notifications (back-office) et consulter
-- l'historique de n'importe quel jeune.
create policy "admin fonij envoie des notifications" on notifications
  for insert with check (public.is_fonij_admin());

create policy "admin fonij lit les notifications" on notifications
  for select using (public.is_fonij_admin());

-- ---------------------------------------------------------------------------
-- 3. Vue globale admin FONIJ (tous les profils, toutes les candidatures)
--    Nécessaire pour les pages /jeunes et /jeunes/[id] du back-office.
-- ---------------------------------------------------------------------------

create policy "admin fonij lit tous les profils" on profiles
  for select using (public.is_fonij_admin());

create policy "admin fonij lit toutes les candidatures" on candidatures
  for select using (public.is_fonij_admin());

create policy "admin fonij met a jour les candidatures" on candidatures
  for update using (public.is_fonij_admin())
  with check (public.is_fonij_admin());

-- ---------------------------------------------------------------------------
-- 4. Publication Realtime (obligatoire pour que l'app reçoive les événements)
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table notifications;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- 5. Notification automatique au jeune quand sa candidature change de statut
--    (déclenchée par le back-office : acceptée / refusée / en attente)
-- ---------------------------------------------------------------------------

create or replace function public.notifier_changement_statut()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.statut is distinct from old.statut then
    insert into notifications (user_id, titre, message, type, envoyee_par)
    values (
      new.user_id,
      'Votre candidature a été mise à jour',
      case new.statut
        when 'acceptee' then 'Félicitations, votre candidature a été acceptée !'
        when 'refusee' then 'Votre candidature a été refusée. Ne baissez pas les bras !'
        else 'Votre candidature est de nouveau en attente.'
      end,
      'candidature',
      auth.uid()
    );
  end if;
  return new;
end;
$$;

create trigger trg_notifier_changement_statut
after update of statut on candidatures
for each row execute function public.notifier_changement_statut();
