/// Libellés français pour les types d'offres.
String typeLabel(String type) {
  switch (type) {
    case 'formation':
      return 'Formation';
    case 'stage':
      return 'Stage';
    case 'emploi':
      return 'Emploi';
    case 'concours':
      return 'Concours';
    case 'bootcamp':
      return 'Bootcamp';
    default:
      return type;
  }
}

/// Libellés français pour le niveau de maîtrise d'une langue.
String niveauLabel(String? niveau) {
  switch (niveau) {
    case 'debutant':
      return 'Débutant';
    case 'intermediaire':
      return 'Intermédiaire';
    case 'courant':
      return 'Courant';
    case 'bilingue':
      return 'Bilingue';
    default:
      return niveau ?? '—';
  }
}

/// Libellés français pour les statuts de candidature.
String statutLabel(String statut) {
  switch (statut) {
    case 'en_attente':
      return 'En attente';
    case 'acceptee':
      return 'Acceptée';
    case 'refusee':
      return 'Refusée';
    default:
      return statut;
  }
}
