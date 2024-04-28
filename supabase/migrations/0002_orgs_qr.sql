-- ============================================================================
-- eFonij — Migration 0002 : identité unique (matricule + QR), organisations,
-- back-office (offres + candidatures) et validations par scan de QR code.
-- Complète la migration 0001 sans la modifier.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Matricule unique sur profiles (généré automatiquement)
-- ---------------------------------------------------------------------------

create sequence if not exists matricule_seq start 1;

alter table profiles add column if not exists matricule text;

-- Backfill des profils déjà inscrits (gaps de séquence possibles : OK).
update profiles
set matricule = 'FONIJ-' || to_char(now(), 'YY') || '-' ||
                lpad(nextval('matricule_seq')::text, 6, '0')
where matricule is null;

alter table profiles add constraint profiles_matricule_key unique (matricule);

-- Génération automatique du matricule à la création du profil.
-- security definer + search_path : nextval s'exécute avec les droits du
-- propriétaire et sans risque d'ombrage du search_path.
create or replace function public.generate_matricule()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.matricule := 'FONIJ-' || to_char(now(), 'YY') || '-' ||
                   lpad(nextval('public.matricule_seq')::text, 6, '0');
  return new;
end;
$$;

create trigger trg_generate_matricule
before insert on profiles
for each row execute function public.generate_matricule();

-- Sécurité supplémentaire : usage de la séquence par les rôles applicatifs.
grant usage on sequence matricule_seq to authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- 2. Organisations : remplace la table "structures" en conservant les données
-- ---------------------------------------------------------------------------

create table organisations (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  type text check (type in ('structure','entreprise','fonij')) not null default 'structure',
  logo_url text,
  contact text,
  created_at timestamptz default now()
);

-- Copie des structures existantes EN CONSERVANT LES MÊMES UUID : les offres
-- déjà rattachées restent donc valides pour la nouvelle clé étrangère.
insert into organisations (id, nom, logo_url, type)
select id, nom, logo_url, 'structure' from structures;

-- Les offres pointent désormais vers organisations.
alter table offres
  drop constraint if exists offres_structure_id_fkey;

alter table offres
  add constraint offres_structure_id_fkey
  foreign key (structure_id) references organisations(id);

drop table structures;

-- ---------------------------------------------------------------------------
-- 3. Comptes back-office rattachés à une organisation
-- ---------------------------------------------------------------------------

create table organisation_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  organisation_id uuid references organisations(id) on delete cascade,
  role text check (role in ('admin','membre')) default 'membre',
  created_at timestamptz default now(),
  unique (user_id, organisation_id)
);

-- ---------------------------------------------------------------------------
-- 4. Validations : scan du QR du passeport (présence / confirmation)
-- ---------------------------------------------------------------------------

create table validations (
  id uuid primary key default gen_random_uuid(),
  candidature_id uuid references candidatures(id) on delete cascade,
  type text check (type in ('presence_evenement','confirmation_candidature')) not null,
  scanned_by_user_id uuid references auth.users(id),
  scanned_by_organisation_id uuid references organisations(id),
  scanned_at timestamptz default now(),
  notes text
);

-- ---------------------------------------------------------------------------
-- 5. Row Level Security
-- ---------------------------------------------------------------------------

-- Aide : l'utilisateur est-il administrateur global FONIJ ?
create or replace function public.is_fonij_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from organisation_users ou
    join organisations o on o.id = ou.organisation_id
    where ou.user_id = auth.uid()
      and o.type = 'fonij'
      and ou.role = 'admin'
  );
$$;

alter table organisations enable row level security;
alter table organisation_users enable row level security;
alter table validations enable row level security;

-- organisations : lecture publique (le nom est affiché dans l'app).
create policy "organisations_select_public" on organisations
  for select using (true);

-- organisation_users : un membre voit son appartenance.
create policy "organisation_users_select_own" on organisation_users
  for select using (auth.uid() = user_id);

-- validations : une organisation membre insère une validation uniquement si
-- la candidature concerne une offre de son organisation, ET si elle attribue
-- le scan à sa propre organisation (pas de fausse attribution).
create policy "validations_insert_org" on validations
  for insert to authenticated with check (
    public.is_fonij_admin()
    or (
      exists (
        select 1
        from candidatures c
        join offres o on o.id = c.offre_id
        join organisation_users ou on ou.organisation_id = o.structure_id
        where c.id = candidature_id
          and ou.user_id = auth.uid()
      )
      and scanned_by_organisation_id in (
        select organisation_id from organisation_users where user_id = auth.uid()
      )
    )
  );

-- validations : lecture par le jeune concerné, l'organisation qui a scanné,
-- ou l'admin FONIJ.
create policy "validations_select_related" on validations
  for select using (
    public.is_fonij_admin()
    or exists (
      select 1 from candidatures c
      where c.id = candidature_id and c.user_id = auth.uid()
    )
    or exists (
      select 1 from organisation_users ou
      where ou.organisation_id = scanned_by_organisation_id
        and ou.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 6. Back-office : policies manquantes pour offres et candidatures
-- ---------------------------------------------------------------------------

-- offres : un membre de l'organisation propriétaire (ou l'admin FONIJ) peut
-- créer / modifier / supprimer ses offres.
create policy "offres_insert_org" on offres
  for insert to authenticated with check (
    public.is_fonij_admin()
    or exists (
      select 1 from organisation_users ou
      where ou.organisation_id = structure_id
        and ou.user_id = auth.uid()
    )
  );

create policy "offres_update_org" on offres
  for update to authenticated
  using (
    public.is_fonij_admin()
    or exists (
      select 1 from organisation_users ou
      where ou.organisation_id = structure_id
        and ou.user_id = auth.uid()
    )
  )
  with check (
    public.is_fonij_admin()
    or exists (
      select 1 from organisation_users ou
      where ou.organisation_id = structure_id
        and ou.user_id = auth.uid()
    )
  );

create policy "offres_delete_org" on offres
  for delete to authenticated using (
    public.is_fonij_admin()
    or exists (
      select 1 from organisation_users ou
      where ou.organisation_id = structure_id
        and ou.user_id = auth.uid()
    )
  );

-- candidatures : l'organisation propriétaire de l'offre (ou l'admin FONIJ)
-- lit et met à jour le statut des candidatures reçues.
create policy "candidatures_select_org" on candidatures
  for select to authenticated using (
    public.is_fonij_admin()
    or exists (
      select 1
      from offres o
      join organisation_users ou on ou.organisation_id = o.structure_id
      where o.id = offre_id
        and ou.user_id = auth.uid()
    )
  );

create policy "candidatures_update_org" on candidatures
  for update to authenticated
  using (
    public.is_fonij_admin()
    or exists (
      select 1
      from offres o
      join organisation_users ou on ou.organisation_id = o.structure_id
      where o.id = offre_id
        and ou.user_id = auth.uid()
    )
  )
  with check (
    public.is_fonij_admin()
    or exists (
      select 1
      from offres o
      join organisation_users ou on ou.organisation_id = o.structure_id
      where o.id = offre_id
        and ou.user_id = auth.uid()
    )
  );
