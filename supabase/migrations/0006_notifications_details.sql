-- ============================================================================
-- eFonij — Migration 0006 : Notifications de statut détaillées
-- ----------------------------------------------------------------------------
-- La notification « votre candidature a été acceptée/refusée » était trop
-- générique : le jeune ne savait pas de quelle offre il s'agissait.
-- Cette migration enrichit le trigger notifier_changement_statut pour
-- inclure le titre de l'offre, son type (formation, stage, emploi…),
-- la structure qui publie et le lieu.
-- ============================================================================

create or replace function public.notifier_changement_statut()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_titre text;
  v_type_label text;
  v_org text;
  v_lieu text;
begin
  if new.statut is distinct from old.statut then
    select o.titre,
           o.lieu,
           og.nom,
           case o.type
             when 'formation' then 'Formation'
             when 'stage' then 'Stage'
             when 'emploi' then 'Emploi'
             when 'concours' then 'Concours'
             when 'bootcamp' then 'Bootcamp'
             else null
           end
      into v_titre, v_lieu, v_org, v_type_label
      from offres o
      left join organisations og on og.id = o.structure_id
     where o.id = new.offre_id;

    insert into notifications (user_id, titre, message, type, envoyee_par)
    values (
      new.user_id,
      case new.statut
        when 'acceptee' then 'Candidature acceptée'
        when 'refusee' then 'Candidature non retenue'
        else 'Candidature en attente'
      end,
      case new.statut
        when 'acceptee' then
          format(
            'Félicitations ! Vous avez été accepté(e) pour « %s »%s — %s%s. '
            'La structure vous contactera pour la suite.',
            coalesce(v_titre, 'cette offre'),
            case when v_type_label is not null then ' (' || v_type_label || ')' else '' end,
            coalesce(v_org, 'la structure'),
            case when v_lieu is not null then ' à ' || v_lieu else '' end
          )
        when 'refusee' then
          format(
            'Votre candidature pour « %s »%s — %s%s n''a pas été retenue. '
            'Ne baissez pas les bras !',
            coalesce(v_titre, 'cette offre'),
            case when v_type_label is not null then ' (' || v_type_label || ')' else '' end,
            coalesce(v_org, 'la structure'),
            case when v_lieu is not null then ' à ' || v_lieu else '' end
          )
        else
          format(
            'Votre candidature pour « %s »%s — %s%s est de nouveau en attente.',
            coalesce(v_titre, 'cette offre'),
            case when v_type_label is not null then ' (' || v_type_label || ')' else '' end,
            coalesce(v_org, 'la structure'),
            case when v_lieu is not null then ' à ' || v_lieu else '' end
          )
      end,
      'candidature',
      auth.uid()
    );
  end if;
  return new;
end;
$$;
