# Mintza

Application iOS d’apprentissage du basque, API PHP et scripts MariaDB.

- `Mintza/` : application iOS ; ouvrir `Mintza/Mintza.xcodeproj` dans Xcode.
- `serveur/` : API PHP, exemple de configuration et tests. Voir [les instructions du serveur](serveur/LISEZMOI.md).
- `database/` : schéma SQL et leçons/exercices. Voir [les instructions SQL](database/README.md).

## Vérifier le backend localement

PHP 8.1 ou supérieur :

```bash
php serveur/tests/verifier.php
MINTZA_MODE=demonstration php -S 127.0.0.1:8000 -t serveur/public
```

Exemple : `http://127.0.0.1:8000/index.php?route=lecons`.
En mode `bdd`, configurer la connexion MariaDB dans `/etc/mintza/base_de_donnees.php` ou définir `MINTZA_CONFIGURATION_BDD` vers un fichier de configuration local.

Le dépôt contient le code et les scripts SQL. Il ne synchronise pas automatiquement les données MariaDB ni le déploiement sur la VM. Les identifiants SQL ne doivent pas être ajoutés à Git.
