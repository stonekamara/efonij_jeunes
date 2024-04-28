-- ============================================================================
-- eFonij — Migration 0009 : Communautés possédées par les organisations
-- ----------------------------------------------------------------------------
-- Objectifs :
--  1. Chaque communauté est rattachée à une organisation (son créateur) via
--     une colonne structure_id sur communautes.
--  2. Une structure ne peut publier que dans les communautés qu'elle possède
--     (et un jeune que dans les communautés dont il est membre).
--  3. La structure propriétaire (et l'admin FONIJ, et l'auteur) peuvent
--     supprimer les publications — le back-office peut donc administrer
--     tous les posts.
--  4. Une structure peut créer / modifier / supprimer SES communautés.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Colonne créateur + backfill des communautés existantes vers FONIJ
-- ---------------------------------------------------------------------------

alter table communautes
  add column if not exists structure_id uuid references organisations(id);

-- Les communautés déjà créées (via l'admin FONIJ) appartiennent à FONIJ.
update communautes
set structure_id = (select id from organisations where type = 'fonij' limit 1)
where structure_id is null;

-- ---------------------------------------------------------------------------
-- 2. Publications : insertion réservée aux membres / structures propriétaires
-- ---------------------------------------------------------------------------

drop policy if exists "publications_insert_auth" on publications;

create policy "publications_insert_membre_ou_structure" on publications
  for insert to authenticated with check (
    auth.uid() = auteur_id
    and (
      public.is_fonij_admin()
      or exists (
        select 1 from communaute_membres cm
        where cm.communaute_id = communaute_id
          and cm.user_id = auth.uid()
      )
      or exists (
        select 1
        from communautes c
        join organisation_users ou on ou.organisation_id = c.structure_id
        where c.id = communaute_id
          and ou.user_id = auth.uid()
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Publications : suppression par l'auteur, la structure propriétaire de la
--    communauté, ou l'admin FONIJ
-- ---------------------------------------------------------------------------

drop policy if exists "publications_delete_auteur" on publications;

create policy "publications_delete_proprietaire" on publications
  for delete to authenticated using (
    auth.uid() = auteur_id
    or public.is_fonij_admin()
    or exists (
      select 1
      from communautes c
      join organisation_users ou on ou.organisation_id = c.structure_id
      where c.id = communaute_id
        and ou.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Communautés : la structure propriétaire gère sa communauté (l'admin FONIJ
--    conserve sa policy existante de 0005)
-- ---------------------------------------------------------------------------

create policy "structure gere sa communaute" on communautes
  for all using (
    exists (
      select 1 from organisation_users ou
      where ou.organisation_id = structure_id
        and ou.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from organisation_users ou
      where ou.organisation_id = structure_id
        and ou.user_id = auth.uid()
    )
  );
