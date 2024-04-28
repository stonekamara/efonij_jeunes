-- ============================================================================
-- eFonij — Migration 0010 : Modification de ses propres publications
-- ----------------------------------------------------------------------------
-- Objectif : permettre à un jeune (ou une structure) de modifier LE contenu
-- de ses propres posts depuis l'app mobile.
-- Sécurité :
--   - seul l'auteur peut mettre à jour (auth.uid() = auteur_id)
--   - le contenu doit rester non vide
--   - la communauté de rattachement ne peut pas être changée (le post ne
--     peut pas être « déplacé » vers une autre communauté).
--     NB : une sous-requête dans WITH CHECK verrait la NOUVELLE version de
--     la ligne (visibilité intra-commande) → protection par trigger, fiable.
-- ============================================================================

drop policy if exists "publications_update_auteur" on publications;

create policy "publications_update_auteur" on publications
  for update to authenticated
  using (auth.uid() = auteur_id)
  with check (
    auth.uid() = auteur_id
    and contenu is not null
    and length(btrim(contenu)) > 0
  );

-- Interdit de déplacer un post vers une autre communauté (pour tout le monde).
create or replace function public.empecher_changement_communaute()
returns trigger
language plpgsql
as $$
begin
  if new.communaute_id is distinct from old.communaute_id then
    raise exception 'Impossible de déplacer une publication vers une autre communauté.';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_publications_communaute_fixe on publications;
create trigger trg_publications_communaute_fixe
  before update on publications
  for each row execute function public.empecher_changement_communaute();
