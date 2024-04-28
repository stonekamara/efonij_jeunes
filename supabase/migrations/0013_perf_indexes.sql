-- ============================================================================
-- eFonij — Migration 0013 : index de performance
-- ----------------------------------------------------------------------------
-- La base est légère aujourd'hui, mais ces index évitent les séquences
-- complètes (seq scan) dès que les volumes augmentent : offres, candidatures,
-- publications, notifications, validations, sections CV.
-- ============================================================================

-- Offres (filtres structure / statut / tri date)
create index if not exists offres_structure_id_idx on public.offres (structure_id);
create index if not exists offres_statut_idx on public.offres (statut);
create index if not exists offres_created_at_idx on public.offres (created_at desc);

-- Candidatures (liste des candidatures d'un jeune)
create index if not exists candidatures_user_id_idx on public.candidatures (user_id);

-- Publications (fil d'une communauté + tri)
create index if not exists publications_communaute_id_idx on public.publications (communaute_id);
create index if not exists publications_created_at_idx on public.publications (created_at desc);

-- Likes / commentaires d'une publication
create index if not exists publication_likes_publication_id_idx on public.publication_likes (publication_id);
create index if not exists publication_commentaires_publication_id_idx on public.publication_commentaires (publication_id);

-- Membres d'une communauté (par jeune)
create index if not exists communaute_membres_user_id_idx on public.communaute_membres (user_id);

-- Validations (par candidature, et par organisation + période)
create index if not exists validations_candidature_id_idx on public.validations (candidature_id);
create index if not exists validations_org_scanned_idx on public.validations (scanned_by_organisation_id, scanned_at);

-- Sections CV (par CV)
create index if not exists cv_competences_cv_id_idx on public.cv_competences (cv_id);
create index if not exists cv_experiences_cv_id_idx on public.cv_experiences (cv_id);
create index if not exists cv_formations_cv_id_idx on public.cv_formations (cv_id);
create index if not exists cv_langues_cv_id_idx on public.cv_langues (cv_id);
