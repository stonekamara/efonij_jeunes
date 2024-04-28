-- ============================================================================
-- eFonij Jeunes — Données de test
-- 2 organisations, 6 offres (une par type, sur 5 piliers), 3 communautés
-- et quelques publications de test par communauté.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Organisations partenaires (ex-structures, cf. migration 0002)
-- ---------------------------------------------------------------------------
insert into organisations (nom, type, logo_url) values
  ('AGRO-Guinée', 'structure', null),
  ('TechLab Conakry', 'structure', null);

-- ---------------------------------------------------------------------------
-- Offres (une par type, réparties sur au moins 3 piliers)
-- ---------------------------------------------------------------------------
with s as (select id, nom from organisations)
insert into offres (titre, type, description, prerequis, public_cible, lieu, pilier, structure_id, date_limite, statut)
select
  'Technicien(ne) agricole',
  'emploi',
  'Encadrement des jeunes producteurs : itinéraires techniques, suivi des parcelles et appui à la commercialisation.',
  'Diplôme en agronomie ou expérience équivalente, permis moto souhaité.',
  'Jeunes diplômés de Kindia et environs',
  'Kindia',
  'AG',
  s.id,
  current_date + interval '30 days',
  'ouverte'
from s where s.nom = 'AGRO-Guinée';

with s as (select id, nom from organisations)
insert into offres (titre, type, description, prerequis, public_cible, lieu, pilier, structure_id, date_limite, statut)
select
  'Formation en gestion de projet culturel',
  'formation',
  'Formation intensive de 3 semaines : montage de projet, budget, mécénat et diffusion culturelle.',
  'Aucun prérequis technique, motivation exigée.',
  'Jeunes passionnés de culture',
  'Conakry',
  'ED',
  s.id,
  current_date + interval '20 days',
  'ouverte'
from s where s.nom = 'TechLab Conakry';

with s as (select id, nom from organisations)
insert into offres (titre, type, description, prerequis, public_cible, lieu, pilier, structure_id, date_limite, statut)
select
  'Stage développeur·se mobile Flutter',
  'stage',
  'Stage de 4 mois au sein de l''équipe produit : développement d''applications Flutter pour le secteur public.',
  'Connaissances de base en Dart/Flutter, portfolio de préférence.',
  'Étudiant·es en informatique (niveau Bac+2 minimum)',
  'Conakry (hybride)',
  'IT',
  s.id,
  current_date + interval '15 days',
  'ouverte'
from s where s.nom = 'TechLab Conakry';

with s as (select id, nom from organisations)
insert into offres (titre, type, description, prerequis, public_cible, lieu, pilier, structure_id, date_limite, statut)
select
  'Bootcamp Data & Intelligence Artificielle',
  'bootcamp',
  'Bootcamp de 6 semaines à temps plein : Python, SQL, machine learning et projets réels.',
  'Bases en programmation recommandées.',
  'Jeunes de 18 à 35 ans',
  'Conakry',
  'IT',
  s.id,
  current_date + interval '25 days',
  'ouverte'
from s where s.nom = 'TechLab Conakry';

with s as (select id, nom from organisations)
insert into offres (titre, type, description, prerequis, public_cible, lieu, pilier, structure_id, date_limite, statut)
select
  'Concours de business plan des jeunes entrepreneurs',
  'concours',
  'Présentez votre projet entrepreneurial et gagnez un accompagnement et un financement de départ.',
  'Business plan d''une page.',
  'Jeunes porteurs de projet',
  'Conakry',
  'EC',
  s.id,
  current_date + interval '45 days',
  'ouverte'
from s where s.nom = 'AGRO-Guinée';

with s as (select id, nom from organisations)
insert into offres (titre, type, description, prerequis, public_cible, lieu, pilier, structure_id, date_limite, statut)
select
  'Formation secourisme & santé communautaire',
  'formation',
  'Formation certifiante aux gestes de premiers secours et à la santé communautaire en milieu rural.',
  'Aucun prérequis.',
  'Jeunes volontaires des communes rurales',
  'Boké',
  'SA',
  s.id,
  current_date + interval '35 days',
  'ouverte'
from s where s.nom = 'AGRO-Guinée';

-- ---------------------------------------------------------------------------
-- Communautés
-- ---------------------------------------------------------------------------
insert into communautes (nom, slug, description, pilier) values
  ('AgriJeunes', 'agrijeunes', 'La communauté des jeunes agriculteurs et transformateurs : échanges de terrain, astuces et entraide.', 'AG'),
  ('Digital Guinée', 'digital-guinee', 'Tech, code et infrastructures : les bâtisseurs du numérique guinéen.', 'IT'),
  ('Santé pour Tous', 'sante-pour-tous', 'Échanges autour de la santé, du bien-être et de la prévention.', 'SA');

-- ---------------------------------------------------------------------------
-- Publications de test
-- NOTE : les publications référencent un auteur (profiles). Elles ne peuvent
-- être insérées qu''une fois au moins un utilisateur inscrit via l''app
-- (le trigger crée sa ligne profiles automatiquement). Réexécutez ce script
-- après votre première inscription pour remplir les fils.
-- ---------------------------------------------------------------------------
insert into publications (communaute_id, auteur_id, contenu)
select c.id, p.id, 'Bienvenue à toutes et à tous ! Présentez-vous dans ce fil et partagez vos expériences de terrain 🌱'
from communautes c, profiles p
where c.slug = 'agrijeunes'
limit 1;

insert into publications (communaute_id, auteur_id, contenu)
select c.id, p.id, 'Quelqu''un a des retours sur le bootcamp Data de TechLab ? Je hésite à m''inscrire.'
from communautes c, profiles p
where c.slug = 'digital-guinee'
limit 1;

insert into publications (communaute_id, auteur_id, contenu)
select c.id, p.id, 'Petit rappel : la campagne de vaccination gratuite a lieu samedi au centre de santé. Venez nombreux ! 💚'
from communautes c, profiles p
where c.slug = 'sante-pour-tous'
limit 1;

-- Adhésions de test (idempotent).
insert into communaute_membres (communaute_id, user_id)
select c.id, p.id
from communautes c, profiles p
where c.slug in ('agrijeunes', 'digital-guinee')
on conflict do nothing;
