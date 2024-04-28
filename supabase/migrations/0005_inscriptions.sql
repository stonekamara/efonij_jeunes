-- ============================================================================
-- eFonij — Migration 0005 : Inscriptions des organisations (demande + validation)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Statut d'une organisation : en attente de validation par l'admin FONIJ.
--    Les organisations existantes restent actives.
-- ---------------------------------------------------------------------------

alter table organisations
  add column if not exists statut text not null default 'active'
  check (statut in ('en_attente', 'active', 'refusee'));

-- L'admin FONIJ approuve/refuse les demandes (met à jour le statut).
create policy "admin fonij modifie les organisations" on organisations
  for update using (public.is_fonij_admin())
  with check (public.is_fonij_admin());

-- L'admin FONIJ voit qui est rattaché à chaque organisation (liste des demandes).
create policy "admin fonij lit les appartenances" on organisation_users
  for select using (public.is_fonij_admin());

-- ---------------------------------------------------------------------------
-- 2. Demande d'accès : crée une organisation « en_attente » et rattache
--    l'utilisateur qui vient de s'inscrire (sécurisé : function definer).
-- ---------------------------------------------------------------------------

create or replace function public.demander_acces_organisation(
  p_user_id uuid,
  p_nom text,
  p_type text,
  p_contact text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org uuid;
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'Utilisateur introuvable.');
  end if;
  if p_nom is null or length(trim(p_nom)) < 2 then
    return jsonb_build_object('ok', false, 'error', 'Le nom de l''organisation est obligatoire.');
  end if;
  if p_type not in ('structure', 'entreprise') then
    return jsonb_build_object('ok', false, 'error', 'Type d''organisation invalide.');
  end if;

  -- Une seule demande / organisation active par compte.
  if exists (
    select 1
    from organisation_users ou
    join organisations o on o.id = ou.organisation_id
    where ou.user_id = p_user_id
      and o.statut in ('en_attente', 'active')
  ) then
    return jsonb_build_object(
      'ok', false,
      'error', 'Vous avez déjà une demande en attente ou une organisation active.'
    );
  end if;

  insert into organisations (nom, type, contact, statut)
  values (
    trim(p_nom),
    p_type,
    nullif(trim(coalesce(p_contact, '')), ''),
    'en_attente'
  )
  returning id into v_org;

  insert into organisation_users (user_id, organisation_id, role)
  values (p_user_id, v_org, 'admin');

  return jsonb_build_object('ok', true, 'organisation_id', v_org);
end;
$$;

-- Appelable depuis le back-office (inscription publique) par tout visiteur.
grant execute on function public.demander_acces_organisation to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Communautés : l'admin FONIJ les crée / modère depuis le back-office.
--    La lecture publique des jeunes est déjà couverte par 0001.
-- ---------------------------------------------------------------------------

create policy "admin fonij gere les communautes" on communautes
  for all using (public.is_fonij_admin())
  with check (public.is_fonij_admin());
