-- ============================================================================
-- eFonij — Migration 0008 : Publications des structures dans les communautés
-- ----------------------------------------------------------------------------
-- Objectifs :
--  1. Permettre aux structures (via le back-office) de publier dans les
--     communautés (la policy publications_insert_auth existe déjà : il suffit
--     que auteur_id = auth.uid(), ce que fait le back-office).
--  2. Fournir à l'app mobile un fil complet avec le statut « auteur structure »
--     (pour n'afficher le badge vérifié que sur les posts des structures) :
--     fonction RPC fil_communautes qui retourne publications + infos auteur +
--     nom de l'organisation + likes / commentaires / liked_by_me.
--  3. Autoriser l'auteur (et l'admin FONIJ) à supprimer sa publication.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Fil de publications enrichi (une seule requête pour l'app mobile)
-- ---------------------------------------------------------------------------

create or replace function public.fil_communautes(p_communaute_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Connexion requise.';
  end if;

  select coalesce(
           jsonb_agg(j order by (j ->> 'created_at') desc),
           '[]'::jsonb
         )
    into v_result
  from (
    select jsonb_build_object(
      'id', p.id,
      'communaute_id', p.communaute_id,
      'auteur_id', p.auteur_id,
      'contenu', p.contenu,
      'image_url', p.image_url,
      'created_at', p.created_at,
      'auteur_prenom', pr.prenom,
      'auteur_nom', pr.nom,
      'auteur_avatar_url', pr.avatar_url,
      'auteur_org_nom', (
        select o.nom
        from organisation_users ou
        join organisations o on o.id = ou.organisation_id
        where ou.user_id = p.auteur_id
        limit 1
      ),
      'auteur_est_organisation', exists (
        select 1 from organisation_users ou
        where ou.user_id = p.auteur_id
      ),
      'likes_count', (
        select count(*) from publication_likes pl
        where pl.publication_id = p.id
      ),
      'commentaires_count', (
        select count(*) from publication_commentaires pc
        where pc.publication_id = p.id
      ),
      'liked_by_me', exists (
        select 1 from publication_likes pl
        where pl.publication_id = p.id
          and pl.user_id = auth.uid()
      )
    ) as j
    from publications p
    left join profiles pr on pr.id = p.auteur_id
    where p.communaute_id = p_communaute_id
  ) s;

  return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Suppression d'une publication par son auteur (ou l'admin FONIJ)
-- ---------------------------------------------------------------------------

create policy "publications_delete_auteur" on publications
  for delete to authenticated using (
    auth.uid() = auteur_id or public.is_fonij_admin()
  );
