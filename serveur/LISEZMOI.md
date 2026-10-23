# API PHP Mintza — première étape

PHP 8.1+ ; aucune bibliothèque ni Composer nécessaires. Les fichiers sont préparés localement : aucun déploiement sur la VM n’a été effectué.

## Organisation

```text
serveur/
├── public/index.php                  Entrée HTTP et choix de la route
├── sources/reponse.php                  Réponses JSON et codes HTTP
├── sources/base_de_donnees.php                  Choix du mode et connexion PDO
├── sources/controleurs/catalogue.php     Validation des paramètres et réponses
├── sources/acces_donnees/catalogue.php    Lectures des données et requêtes SQL
├── sources/donnees_exemple/catalogue.json        Données fictives sans MariaDB
├── configuration/base_de_donnees.exemple.php       Modèle de configuration sans secret
└── tests/verifier.php                      Vérifications du mode démonstration
```

Trajet : requête iOS → index → contrôleur → fichier d’accès aux données → données → réponse JSON.

Un contrôleur traite la demande HTTP ; un fichier d’accès aux données contient les accès aux données. Il n’y a pas de pages HTML à produire : SwiftUI construit les écrans. Pour ce petit projet, un catalogue commun suffit ; ajouter plus tard des fichiers dédiés aux favoris et à la progression lorsqu’on implémente ces fonctionnalités.

## Tester sans base

Depuis le dossier serveur :

```bash
php -S 127.0.0.1:8000 -t public
```

Laisser ce terminal ouvert. Dans un deuxième terminal sur la même machine :

```bash
curl -i 'http://127.0.0.1:8000/index.php?route=sante'
curl 'http://127.0.0.1:8000/index.php?route=lecons'
curl 'http://127.0.0.1:8000/index.php?route=exercices&idLecon=1'
curl 'http://127.0.0.1:8000/index.php?route=commerces'
```

`sante` retourne `{"statut":"ok","application":"Mintza","mode":"demonstration"}`. Il confirme que PHP fonctionne, pas que MariaDB est accessible. Le mode `demonstration`, utilisé par défaut, fournit 6 leçons, 24 exercices et 4 commerces validés issus du SQL simplifié. Aucun SQL ni compte n’est nécessaire. Les données de démonstration sont fixes, sans enregistrement des modifications.

Arrêter le serveur de test avec Ctrl+C. Pour lancer les vérifications :

```bash
php tests/verifier.php
```

Le serveur PHP intégré sert aux essais. Apache servira ensuite l’API sur la VM.

## Contrat pour SwiftUI

| Méthode | Route | Réponse |
|---|---|---|
| GET | `index.php?route=sante` | Objet de diagnostic PHP |
| GET | `index.php?route=lecons` | Tableau des leçons |
| GET | `index.php?route=exercices&idLecon=1` | Tableau des exercices de la leçon |
| GET | `index.php?route=commerces` | Tableau des commerces validés |

`route` est un paramètre d’URL ; aucune réécriture Apache n’est nécessaire. Cette convention remplace les routes en fichiers séparés proposées précédemment. Toujours citer l’URL entre guillemets dans le shell quand elle contient `&`.

Succès : HTTP 200. Paramètre invalide : 400 ; route ou leçon absente : 404 ; méthode non autorisée : 405 ; erreur de configuration : 500 ; erreur SQL/connexion : 503. Les erreurs sont des objets `{"erreur":"Message"}`, les listes sont des tableaux JSON, y compris `[]` pour une liste vide.

Les identifiants et ordres sont des nombres entiers ; les coordonnées des nombres ou `null`. `contenuExo` et `reponseExo` sont décodés en JSON imbriqué, pas renvoyés comme chaînes. Les champs facultatifs peuvent être `null`.

**Prototype pédagogique :** les exercices comprennent leur correction et explication pour permettre la correction locale dans l’app. Ce contrat ne convient pas à un quiz dont les réponses doivent rester secrètes ; pour une évaluation réelle, ajouter une correction côté serveur et retirer les réponses des données envoyées.

Ces routes lisent le catalogue public. Aucun accès aux profils, aucune authentification ni route d’écriture n’est implémenté à cette étape.

## Transfert sur la VM

Exemple avec un emplacement explicite `/opt/mintza/serveur`. Si vous avez déjà un autre emplacement, adaptez les chemins ; ne mettez pas tout le dossier serveur dans un dossier web public.

Sur la VM :

```bash
mkdir -p /opt/mintza
```

Sur le Mac, dans un autre terminal :

```bash
scp -r /Users/etudiant/Documents/Mintza/serveur root@10.3.16.227:/opt/mintza/
```

Sur la VM :

```bash
cd /opt/mintza/serveur
php -v
php tests/verifier.php
php -S 127.0.0.1:8000 -t public
```

Pour tester depuis un navigateur sur le Mac sans ouvrir le port 8000 de la VM, créer un tunnel dans un autre terminal du Mac :

```bash
ssh -N -L 8000:127.0.0.1:8000 root@10.3.16.227
```

Puis ouvrir `http://127.0.0.1:8000/index.php?route=sante` sur le Mac. Les deux terminaux restent ouverts pendant l’essai. Si le port 8000 du Mac est occupé, utiliser `-L 8001:127.0.0.1:8000` et ouvrir le port 8001.

## Apache sur Debian/Ubuntu, lorsqu’il est installé

Seul `public` est exposé. Ne pas exposer `sources`, `configuration`, `tests` ou le dossier SQL.

Créer `/etc/apache2/conf-available/mintza.conf` avec :

```apache
Alias /api/ /opt/mintza/serveur/public/

<Directory /opt/mintza/serveur/public>
    Options -Indexes
    AllowOverride None
    Require all granted
    DirectoryIndex index.php
    SetEnv MINTZA_MODE demonstration
</Directory>
```

Puis, sur la VM :

```bash
a2enmod env
a2enconf mintza
apache2ctl configtest
```

Si le résultat est `Syntax OK` :

```bash
systemctl reload apache2
curl -i 'http://127.0.0.1/api/index.php?route=sante'
```

Depuis le réseau autorisé/VPN : `http://10.3.16.227/api/index.php?route=sante`. Le code sous `/opt/mintza` doit être lisible par Apache ; les dossiers créés par défaut avec permissions 755 et les fichiers 644 conviennent. Aucun besoin de donner les droits d’écriture du code à Apache.

## Passer à MariaDB plus tard

1. Importer la base simplifiée et créer l’utilisateur SQL `mintza_app`.
2. Copier le modèle de configuration vers `/etc/mintza/base_de_donnees.php`, hors dépôt :

```bash
install -d -o root -g www-data -m 750 /etc/mintza
install -o root -g www-data -m 640 /opt/mintza/serveur/configuration/base_de_donnees.exemple.php /etc/mintza/base_de_donnees.php
nano /etc/mintza/base_de_donnees.php
```

Cette copie remplace le fichier cible : si vous l’avez déjà configuré, éditez-le directement au lieu de le remplacer. Renseigner le véritable mot de passe SQL uniquement dans ce fichier.

3. Dans la configuration Apache, remplacer `SetEnv MINTZA_MODE demonstration` par `SetEnv MINTZA_MODE bdd`, vérifier la syntaxe et recharger Apache.
4. Tester la route des leçons pour vérifier la connexion réelle. `sante` seul ne vérifie pas SQL.

Pour un essai avec le serveur PHP intégré à la place d’Apache :

```bash
MINTZA_MODE=bdd php -S 127.0.0.1:8000 -t public
```

Il n’existe pas de basculement silencieux vers les données fictives en cas de panne SQL. Le mode affiché dans sante permet de savoir quelle source est choisie.

PDO et ses requêtes préparées sont décrits dans la [documentation PHP](https://www.php.net/manual/en/pdo.prepare.php). Les paramètres utilisateur sont transmis séparément des instructions SQL.

## Noms francisés

Le dossier local `backend` a été renommé `serveur`. La route `health` devient `sante`. Les modes `demo` et `database` deviennent `demonstration` et `bdd`. Si une ancienne copie était déjà installée sur la VM, adapter aussi les chemins Apache et les appels iOS. Aucun changement distant n’a été effectué.

La configuration privée utilise désormais `/etc/mintza/base_de_donnees.php` avec les clés `chaineConnexion`, `utilisateur` et `motDePasse` (voir le modèle). L’ancien fichier `/etc/mintza/database.php` et ses clés `dsn`, `user`, `password` ne sont plus lus automatiquement. La variable de chemin facultative est maintenant `MINTZA_CONFIGURATION_BDD`.

Les mots-clés PHP (`function`, `return`, etc.), fonctions natives (`json_encode`, etc.), méthodes PDO, en-têtes HTTP et directives Apache gardent leurs noms imposés. Les identifiants du projet sont en français sans accents pour faciliter la saisie. Le schéma SQL existant et ses champs restent inchangés.
