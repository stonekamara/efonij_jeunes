-- ============================================================================
-- eFonij — Nettoyage des données de test (à relancer manuellement si besoin)
-- ----------------------------------------------------------------------------
-- Supprime :
--   - toutes les offres (test) + candidatures associées (cascade)
--   - la communauté « TechLab Devs » (test) + ses posts/membres (cascade)
--   - toutes les notifications (test)
--   - les comptes de test (techlab, structure-test, candidat-test, demande test)
--     -> cascade profiles -> publications, likes, commentaires, candidatures,
--        cvs, adhésions, notifications
--   - les organisations de test (TechLab Conakry, Structure Test, AGRO-Guinée)
--   - les fichiers de stockage des comptes supprimés
-- Garde : FONIJ, les 3 communautés officielles, hello@moussakamara.com et
-- admin@efonij.gn (+ leurs fichiers).
-- ============================================================================

begin;

-- 1. Offres de test (les candidatures suivent par cascade)
delete from offres;

-- 2. Communauté de test créée par TechLab
delete from communautes where slug like 'techlab-devs%';

-- 3. Notifications de test
delete from notifications;

-- 4. Comptes de test (le profil et toutes ses données suivent par cascade)
delete from auth.users
where email in (
  'techlab@efonij.gn',
  'test.demande.1786203838@gmail.com',
  'structure-test@efonij.gn',
  'candidat-test@efonij.gn'
);

-- 5. Organisations de test (les accès organisation_users suivent par cascade)
delete from organisations
where nom in ('TechLab Conakry', 'Structure Test', 'AGRO-Guinée');

-- 6. Fichiers de stockage des comptes supprimés
delete from storage.objects
where owner in (
  select id from auth.users
  where email in ('techlab@efonij.gn', 'candidat-test@efonij.gn')
);

commit;
