-- ============================================================================
-- eFonij — Migration 0012 : Suppression de structures par l'admin FONIJ
-- ----------------------------------------------------------------------------
-- Complète le « droit suprême » de l'administrateur : il peut désormais
-- supprimer une structure / entreprise depuis son tableau de bord.
-- La fonction nettoie TOUTES les données liées en une seule transaction :
--   - offres de la structure (candidatures + validations en cascade),
--   - communautés de la structure (membres, publications, likes, commentaires
--     en cascade),
--   - validations scannées par cette organisation,
--   - appartenances organisation_users,
--   - les comptes back-office rattachés (auth.users → profiles, sessions,
--     identités en cascade) afin que l'email du compte soit réutilisable,
--   - l'organisation elle-même.
-- Garde-fous : réservé à l'admin FONIJ ; l'organisation « fonij » elle-même
-- (FONIJ Administration) ne peut pas être supprimée.
-- ============================================================================

create or replace function public.supprimer_organisation_par_admin(
  p_org_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_type text;
  v_users uuid[];
begin
  -- Seul l'admin FONIJ peut supprimer une structure.
  if not public.is_fonij_admin() then
    return jsonb_build_object('ok', false, 'error', 'Accès réservé à l''administrateur FONIJ.');
  end if;

  select o.type into v_type
  from organisations o
  where o.id = p_org_id;

  if v_type is null then
    return jsonb_build_object('ok', false, 'error', 'Organisation introuvable.');
  end if;

  -- Protection : on ne supprime jamais l'organisation FONIJ elle-même.
  if v_type = 'fonij' then
    return jsonb_build_object(
      'ok', false,
      'error', 'L''organisation FONIJ ne peut pas être supprimée.'
    );
  end if;

  -- Comptes rattachés à l'organisation.
  select array_agg(ou.user_id)
    into v_users
    from organisation_users ou
   where ou.organisation_id = p_org_id;

  -- 1. Contenu de la structure (candidatures + validations en cascade,
  --    publications/likes/commentaires/membres en cascade).
  delete from offres
  where structure_id = p_org_id;

  delete from communautes
  where structure_id = p_org_id;

  -- 2. Validations scannées par cette organisation (colonne nullable).
  update validations
  set scanned_by_organisation_id = null
  where scanned_by_organisation_id = p_org_id;

  -- 3. Suppression des comptes back-office : on neutralise d'abord les
  --    références sans CASCADE vers auth.users, puis on supprime le compte
  --    (profiles, sessions, identités, organisation_users… en cascade).
  if v_users is not null then
    update candidatures
    set reviewed_by = null
    where reviewed_by = any (v_users);

    update notifications
    set envoyee_par = null
    where envoyee_par = any (v_users);

    update validations
    set scanned_by_user_id = null
    where scanned_by_user_id = any (v_users);

    delete from auth.users
    where id = any (v_users);
  end if;

  -- 4. Appartenances restantes + organisation.
  delete from organisation_users
  where organisation_id = p_org_id;

  delete from organisations
  where id = p_org_id;

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.supprimer_organisation_par_admin to authenticated;
