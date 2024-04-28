-- ============================================================================
-- eFonij — Migration 0003 : CV du jeune (sections + snapshot/PDF par candidature)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. CV courant du jeune (une ligne par utilisateur)
-- ---------------------------------------------------------------------------

create table cvs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references profiles(id) on delete cascade,
  titre_poste text,
  resume text,
  updated_at timestamptz default now()
);

create table cv_formations (
  id uuid primary key default gen_random_uuid(),
  cv_id uuid references cvs(id) on delete cascade,
  diplome text not null,
  etablissement text,
  annee_debut int,
  annee_fin int
);

create table cv_experiences (
  id uuid primary key default gen_random_uuid(),
  cv_id uuid references cvs(id) on delete cascade,
  poste text not null,
  organisation text,
  date_debut date,
  date_fin date,
  description text
);

create table cv_competences (
  id uuid primary key default gen_random_uuid(),
  cv_id uuid references cvs(id) on delete cascade,
  nom text not null
);

create table cv_langues (
  id uuid primary key default gen_random_uuid(),
  cv_id uuid references cvs(id) on delete cascade,
  langue text not null,
  niveau text check (niveau in ('debutant','intermediaire','courant','bilingue'))
);

-- ---------------------------------------------------------------------------
-- 2. Snapshot + PDF par candidature (le CV peut évoluer après)
-- ---------------------------------------------------------------------------

alter table candidatures add column if not exists cv_snapshot jsonb;
alter table candidatures add column if not exists cv_pdf_url text;
alter table candidatures add column if not exists reviewed_at timestamptz;
alter table candidatures add column if not exists reviewed_by uuid references auth.users(id);

-- ---------------------------------------------------------------------------
-- 3. Row Level Security
-- ---------------------------------------------------------------------------

alter table cvs enable row level security;
alter table cv_formations enable row level security;
alter table cv_experiences enable row level security;
alter table cv_competences enable row level security;
alter table cv_langues enable row level security;

create policy "jeune gere son cv" on cvs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "jeune gere ses formations" on cv_formations
  for all using (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()))
  with check (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()));

create policy "jeune gere ses experiences" on cv_experiences
  for all using (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()))
  with check (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()));

create policy "jeune gere ses competences" on cv_competences
  for all using (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()))
  with check (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()));

create policy "jeune gere ses langues" on cv_langues
  for all using (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()))
  with check (exists (select 1 from cvs where cvs.id = cv_id and cvs.user_id = auth.uid()));

-- NOTE : les policies de lecture/mise à jour des candidatures par les
-- organisations existent déjà (migration 0002 : candidatures_select_org,
-- candidatures_update_org) — non recréées ici pour éviter les doublons.

-- ---------------------------------------------------------------------------
-- 4. Storage : bucket "cvs" (URL publique, écriture dans son propre dossier)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('cvs', 'cvs', true)
on conflict (id) do nothing;

create policy "cvs_select_public"
  on storage.objects for select
  using (bucket_id = 'cvs');

create policy "cvs_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'cvs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "cvs_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'cvs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "cvs_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'cvs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
