-- ============================================================================
-- eFonij — Migration 0008 : Moteur de points du Passeport Jeune
-- ----------------------------------------------------------------------------
-- Jusqu'ici les colonnes profiles.points / niveau_passeport n'étaient jamais
-- mises à jour : le système était « décoratif ». Cette migration branche le
-- moteur d'attribution :
--   +10 pts  → candidature envoyée
--   +50 pts  → candidature acceptée par une structure
--   +5 pts   → adhésion à une communauté
--   +20 pts  → CV complété (au moins une formation ET une expérience)
-- Le niveau_passeport (Graine 150 / Pousse 400 / Arbre 700 / Forêt 1000) est
-- recalculé automatiquement à chaque gain.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Flag « points CV déjà attribués » (le bonus CV n'est donné qu'une fois)
-- ---------------------------------------------------------------------------

alter table cvs
  add column if not exists points_cv_attribues boolean not null default false;

-- ---------------------------------------------------------------------------
-- 2. Cœur du moteur : ajoute des points et recalcule le niveau (défini le
--    security definer pour contourner la RLS, comme les autres fonctions).
-- ---------------------------------------------------------------------------

create or replace function public.ajouter_points(
  p_user_id uuid,
  p_delta int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update profiles
     set points = greatest(0, points + p_delta),
         niveau_passeport = case
           when points + p_delta >= 700 then 4  -- Forêt
           when points + p_delta >= 400 then 3  -- Arbre
           when points + p_delta >= 150 then 2  -- Pousse
           else 1                               -- Graine
         end
   where id = p_user_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. +10 pts : candidature envoyée
-- ---------------------------------------------------------------------------

create or replace function public.points_candidature_envoyee()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ajouter_points(new.user_id, 10);
  return new;
end;
$$;

create trigger trg_points_candidature_envoyee
  after insert on candidatures
  for each row execute function public.points_candidature_envoyee();

-- ---------------------------------------------------------------------------
-- 4. +50 pts : candidature acceptée (dès le passage du statut en 'acceptee')
-- ---------------------------------------------------------------------------

create or replace function public.points_candidature_acceptee()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.statut = 'acceptee' and old.statut is distinct from 'acceptee' then
    perform public.ajouter_points(new.user_id, 50);
  end if;
  return new;
end;
$$;

create trigger trg_points_candidature_acceptee
  after update of statut on candidatures
  for each row execute function public.points_candidature_acceptee();

-- ---------------------------------------------------------------------------
-- 5. +5 pts : adhésion à une communauté
-- ---------------------------------------------------------------------------

create or replace function public.points_adhesion_communaute()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ajouter_points(new.user_id, 5);
  return new;
end;
$$;

create trigger trg_points_adhesion_communaute
  after insert on communaute_membres
  for each row execute function public.points_adhesion_communaute();

-- ---------------------------------------------------------------------------
-- 6. +20 pts : CV complété (≥ 1 formation ET ≥ 1 expérience), une seule fois.
--    Déclenché par les modifications sur cv_formations / cv_experiences.
-- ---------------------------------------------------------------------------

create or replace function public.points_cv_complet()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cv_id uuid;
  v_user_id uuid;
begin
  v_cv_id := coalesce(new.cv_id, old.cv_id);
  if v_cv_id is null then
    return coalesce(new, old);
  end if;

  update cvs
     set points_cv_attribues = true
   where id = v_cv_id
     and not points_cv_attribues
     and exists (select 1 from cv_formations where cv_id = v_cv_id)
     and exists (select 1 from cv_experiences where cv_id = v_cv_id)
  returning user_id into v_user_id;

  if v_user_id is not null then
    perform public.ajouter_points(v_user_id, 20);
  end if;

  return coalesce(new, old);
end;
$$;

create trigger trg_points_cv_formations
  after insert or update or delete on cv_formations
  for each row execute function public.points_cv_complet();

create trigger trg_points_cv_experiences
  after insert or update or delete on cv_experiences
  for each row execute function public.points_cv_complet();

-- ---------------------------------------------------------------------------
-- 7. Backfill : met à jour le niveau des profils qui ont déjà des points
--    (permet de rattraper d'éventuels profils existants).
-- ---------------------------------------------------------------------------

update profiles
   set niveau_passeport = case
     when points >= 700 then 4
     when points >= 400 then 3
     when points >= 150 then 2
     else 1
   end
 where niveau_passeport is distinct from (
   case
     when points >= 700 then 4
     when points >= 400 then 3
     when points >= 150 then 2
     else 1
   end
 );
