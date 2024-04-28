-- ============================================================================
-- eFonij — Migration 0011 : Création de structures par l'admin FONIJ
-- ----------------------------------------------------------------------------
-- Objectif : permettre à l'administrateur FONIJ de créer directement une
-- structure / entreprise depuis son tableau de bord (sans passer par une
-- demande d'inscription), avec :
--   - l'organisation créée directement « active » (pas en attente),
--   - le compte back-office créé par le back-office (signUp) puis rattaché
--     à l'organisation avec le rôle « admin ».
-- Sécurité : la fonction vérifie is_fonij_admin() avant toute écriture.
-- ============================================================================

create or replace function public.creer_organisation_par_admin(
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
  -- Seul l'admin FONIJ peut créer une structure.
  if not public.is_fonij_admin() then
    return jsonb_build_object('ok', false, 'error', 'Accès réservé à l''administrateur FONIJ.');
  end if;

  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'Compte de l''organisation introuvable.');
  end if;
  if p_nom is null or length(trim(p_nom)) < 2 then
    return jsonb_build_object('ok', false, 'error', 'Le nom de l''organisation est obligatoire.');
  end if;
  if p_type not in ('structure', 'entreprise') then
    return jsonb_build_object('ok', false, 'error', 'Type d''organisation invalide.');
  end if;

  -- Le compte ne doit pas déjà être rattaché à une organisation.
  if exists (
    select 1 from organisation_users ou
    where ou.user_id = p_user_id
  ) then
    return jsonb_build_object(
      'ok', false,
      'error', 'Ce compte est déjà rattaché à une organisation.'
    );
  end if;

  insert into organisations (nom, type, contact, statut)
  values (
    trim(p_nom),
    p_type,
    nullif(trim(coalesce(p_contact, '')), ''),
    'active'
  )
  returning id into v_org;

  insert into organisation_users (user_id, organisation_id, role)
  values (p_user_id, v_org, 'admin');

  return jsonb_build_object('ok', true, 'organisation_id', v_org);
end;
$$;

grant execute on function public.creer_organisation_par_admin to authenticated;
