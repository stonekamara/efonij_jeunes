-- ============================================================================
-- eFonij Jeunes — Migration initiale
-- Schéma du MVP (côté jeunes) : passeport, piliers, offres, candidatures,
-- communautés, publications, likes, commentaires.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  prenom text not null,
  nom text not null,
  email text not null,
  region text,
  telephone text,
  avatar_url text,
  pilier text check (pilier in ('AG','ED','IT','EC','SA')),
  niveau_passeport int default 1,
  points int default 0,
  created_at timestamptz default now()
);

create table structures (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  logo_url text,
  description text
);

create table offres (
  id uuid primary key default gen_random_uuid(),
  titre text not null,
  type text check (type in ('formation','stage','emploi','concours','bootcamp')),
  description text,
  prerequis text,
  public_cible text,
  lieu text,
  image_url text,
  pilier text check (pilier in ('AG','ED','IT','EC','SA')),
  structure_id uuid references structures(id),
  date_limite date,
  statut text default 'ouverte' check (statut in ('ouverte','fermee')),
  created_at timestamptz default now()
);

create table candidatures (
  id uuid primary key default gen_random_uuid(),
  offre_id uuid references offres(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  statut text default 'en_attente' check (statut in ('en_attente','acceptee','refusee')),
  created_at timestamptz default now(),
  unique (offre_id, user_id)
);

create table communautes (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  slug text unique not null,
  description text,
  avatar_url text,
  pilier text check (pilier in ('AG','ED','IT','EC','SA')),
  created_at timestamptz default now()
);

create table communaute_membres (
  id uuid primary key default gen_random_uuid(),
  communaute_id uuid references communautes(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  joined_at timestamptz default now(),
  unique (communaute_id, user_id)
);

create table publications (
  id uuid primary key default gen_random_uuid(),
  communaute_id uuid references communautes(id) on delete cascade,
  auteur_id uuid references profiles(id) on delete cascade,
  contenu text not null,
  image_url text,
  created_at timestamptz default now()
);

create table publication_likes (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid references publications(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  unique (publication_id, user_id)
);

create table publication_commentaires (
  id uuid primary key default gen_random_uuid(),
  publication_id uuid references publications(id) on delete cascade,
  auteur_id uuid references profiles(id) on delete cascade,
  contenu text not null,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table profiles enable row level security;
alter table structures enable row level security;
alter table offres enable row level security;
alter table candidatures enable row level security;
alter table communautes enable row level security;
alter table communaute_membres enable row level security;
alter table publications enable row level security;
alter table publication_likes enable row level security;
alter table publication_commentaires enable row level security;

-- profiles : écriture restreinte à sa propre ligne.
-- Écart assumé (nécessaire pour afficher les auteurs dans les fils) :
-- la lecture est ouverte à tout utilisateur connecté.
create policy "profiles_select_own" on profiles
  for select using (auth.uid() = id);
create policy "profiles_select_authenticated" on profiles
  for select to authenticated using (true);
create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "profiles_delete_own" on profiles
  for delete using (auth.uid() = id);

-- structures / offres : lecture publique (pas de back-office dans le MVP).
create policy "structures_select_public" on structures
  for select using (true);

create policy "offres_select_public" on offres
  for select using (true);

-- candidatures : uniquement ses propres candidatures.
create policy "candidatures_select_own" on candidatures
  for select using (auth.uid() = user_id);
create policy "candidatures_insert_own" on candidatures
  for insert with check (auth.uid() = user_id);
create policy "candidatures_update_own" on candidatures
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "candidatures_delete_own" on candidatures
  for delete using (auth.uid() = user_id);

-- communautes : lecture publique.
create policy "communautes_select_public" on communautes
  for select using (true);

-- communaute_membres : uniquement ses propres adhésions.
create policy "communaute_membres_select_own" on communaute_membres
  for select using (auth.uid() = user_id);
create policy "communaute_membres_insert_own" on communaute_membres
  for insert with check (auth.uid() = user_id);
create policy "communaute_membres_delete_own" on communaute_membres
  for delete using (auth.uid() = user_id);

-- publications : lecture publique, insertion authentifiée avec auteur imposé.
create policy "publications_select_public" on publications
  for select using (true);
create policy "publications_insert_auth" on publications
  for insert to authenticated with check (auth.uid() = auteur_id);

-- publication_likes : écriture restreinte à soi-même.
-- Écart assumé : lecture ouverte aux connectés pour compter les likes.
create policy "publication_likes_select_auth" on publication_likes
  for select to authenticated using (true);
create policy "publication_likes_insert_own" on publication_likes
  for insert with check (auth.uid() = user_id);
create policy "publication_likes_delete_own" on publication_likes
  for delete using (auth.uid() = user_id);

-- publication_commentaires : lecture publique, insertion authentifiée.
create policy "publication_commentaires_select_public" on publication_commentaires
  for select using (true);
create policy "publication_commentaires_insert_auth" on publication_commentaires
  for insert to authenticated with check (auth.uid() = auteur_id);

-- ---------------------------------------------------------------------------
-- Trigger : création automatique du profil à l'inscription
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, prenom, nom, email)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'prenom', ''), ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'nom', ''), ''),
    coalesce(new.raw_user_meta_data ->> 'email', new.email)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Storage : bucket avatars (un utilisateur ne modifie que son propre fichier)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatars_select_public"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
