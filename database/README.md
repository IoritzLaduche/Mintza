# Base de données Mintza

Scripts SQL de la maquette MariaDB. Ils ne sont pas un export de la base actuellement déployée sur la VM.

Pour une installation neuve :

```bash
mariadb -u UTILISATEUR -p < database/01_creer_base.sql
mariadb -u UTILISATEUR -p < database/exercices_60_a1_c2.sql
```

Le premier script crée `mintza_maquette` et les six tables si elles sont absentes. Il ne met pas à jour la structure des tables déjà présentes.
Le second ajoute six leçons et soixante exercices. L’importer une seule fois : le réexécuter duplique le contenu.
Ne pas réimporter ces scripts sur la VM si les données existent déjà.

Les identifiants de connexion restent sur la VM dans `/etc/mintza/base_de_donnees.php`. Le modèle sans secret se trouve dans `serveur/configuration/base_de_donnees.exemple.php`.
