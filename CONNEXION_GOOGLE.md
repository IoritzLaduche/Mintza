# Activer la connexion Google dans Mintza

Le bouton Apple a été retiré. Le bouton officiel Google est relié au SDK Google Sign-In et à l'API PHP. Le parcours ne simule pas de connexion : tant que les identifiants et HTTPS ne sont pas configurés, il affiche une erreur et ne crée aucune session.

Les deux ID client Google et le schéma de retour iOS sont maintenant renseignés dans `Mintza/ConfigurationReseau.plist`. L’audience serveur correspondante est renseignée dans `serveur/configuration/authentification.exemple.php`. Il reste à définir `MintzaAuthURL` et à effectuer la préparation du serveur décrite ci-dessous.

## 1. Créer le projet Google

1. Ouvrir <https://console.cloud.google.com/>.
2. Sélecteur de projet → Nouveau projet → **Mintza**, puis sélectionner ce projet.
3. Google Auth Platform → Premiers pas : nom Mintza, e-mail d'assistance et de contact.
4. Choisir une audience **Externe** pour les comptes Gmail personnels. En mode Test, ajouter les comptes qui testeront l'application dans Audience → Utilisateurs de test.
5. Utiliser uniquement les permissions de connexion de base (`openid`, `email`, `profile`). Aucune permission Gmail, Drive ou Calendar n'est nécessaire.

La connexion directe avec le SDK Google ne nécessite pas d'abonnement Google payant. L'hébergement du serveur reste distinct.

## 2. Créer deux clients OAuth dans le même projet

Ouvrir <https://console.cloud.google.com/auth/clients> → Créer un client.

### Client iOS

- Type : **iOS**.
- Nom : **Mintza iOS**.
- Identifiant du bundle : **ISA-NUM1.Mintza** (respecter la casse).
- Si l'équipe est demandée : **6Y69UADZ84**, à confirmer avec l'équipe sélectionnée dans Xcode.
- L'identifiant App Store peut rester vide pour ce prototype non publié.
- Copier l'**ID client**, qui se termine par `.apps.googleusercontent.com`.

### Client serveur

- Type : **Application Web**.
- Nom : **Mintza serveur**.
- Copier son **ID client**, distinct de celui d'iOS.
- Le parcours natif retenu transmet un ID token au serveur : aucune URI de redirection web n'est nécessaire pour ce parcours.
- Le **secret client** n'est pas utilisé par cette implémentation. Ne pas l'ajouter à l'application ni au dépôt.

Ces deux ID client sont publics et peuvent être renseignés dans les fichiers de configuration. Ils ne sont pas des mots de passe.

## 3. Donner une adresse HTTPS à l'API

L'adresse du catalogue existant est `http://10.3.16.227/api/index.php`. Elle ne peut pas servir à transmettre les preuves de connexion Google.

Il faut une URL HTTPS avec un certificat reconnu par l'iPhone, par exemple un sous-domaine mis à disposition par l'université. Le nom d'hôte doit être accessible depuis l'iPhone, éventuellement sur le réseau universitaire/VPN. Demander à l'administrateur de la VM un nom DNS et la configuration TLS d'Apache. Il n'est pas nécessaire d'acheter un domaine si l'établissement fournit ce nom et le certificat.

Le serveur PHP doit aussi pouvoir joindre en HTTPS `www.googleapis.com` pour télécharger les clés publiques Google. Si la VM utilise un proxy réseau, renseigner `proxyHttps` dans `/etc/mintza/authentification.php` ; ne pas placer un éventuel mot de passe de proxy dans le dépôt. Aucun mot de passe Google ne transite par Mintza.

Le contrôle serveur exige `HTTPS=on` ou le port serveur 443. Si TLS est terminé par un proxy, configurer explicitement cette information dans Apache depuis le proxy de confiance ; l'application ne fait pas confiance aux en-têtes `X-Forwarded-*` fournis par un client.

## 4. Configurer l'application iOS

Dans `Mintza/ConfigurationReseau.plist`, remplacer :

| Clé | Valeur |
|---|---|
| `MintzaAuthURL` | URL HTTPS complète de `api/index.php`, sans `?route=...` |
| `GIDClientID` | ID client **iOS** |
| `GIDServerClientID` | ID client **Application Web** |
| `CFBundleURLTypes` → `CFBundleURLSchemes` | ID iOS inversé : `123-abc.apps.googleusercontent.com` devient `com.googleusercontent.apps.123-abc` |

Ouvrir `Mintza/Mintza.xcodeproj`. Xcode télécharge GoogleSignIn et GoogleSignInSwift via Swift Package Manager. Le SDK est verrouillé par `Package.resolved`. Le retour OAuth est reçu dans `MintzaApp.swift`.

## 5. Préparer le serveur

Ces opérations sont à effectuer sur la VM, pas sur la base d'exemple du Mac. Aucun déploiement distant n'est effectué par l'ajout des fichiers au dépôt.

1. Déployer le dossier `serveur` complet ; seul `serveur/public` doit être exposé par Apache.
2. Installer PHP 8.1 ou supérieur, PDO MySQL, OpenSSL, cURL et Composer.
3. Depuis `serveur`, lancer `composer install --no-dev --prefer-dist --no-interaction` pour installer les dépendances exactes du fichier lock.
4. Après le schéma existant, importer `database/02_authentification.sql` dans MariaDB. Il ajoute les tables `IdentiteConnexion`, `SessionConnexion`, `DefiConnexion` sans supprimer les comptes ou les leçons.
5. Vérifier que l'utilisateur SQL de l'API dispose des droits SELECT, INSERT, UPDATE et DELETE sur les tables nécessaires (y compris `Utilisateur`).
6. Copier `serveur/configuration/authentification.exemple.php` vers `/etc/mintza/authentification.php`, puis renseigner `googleAudience` avec l'ID client **Application Web**, identique à `GIDServerClientID`.
7. Créer `/var/cache/mintza`, détenu par l'utilisateur PHP (`www-data` sur Debian/Ubuntu), permissions 700. La configuration `/etc/mintza/authentification.php` doit être lisible par PHP, hors du dossier public.
8. Configurer `MINTZA_MODE=bdd` et la connexion SQL existante. La connexion Google n'utilise jamais les données de démonstration.
9. Pour Apache avec PHP-FPM, vérifier que l'en-tête `Authorization` est transmis à PHP ; selon la configuration, `CGIPassAuth On` peut être nécessaire.

Le fichier de configuration peut être déplacé via `MINTZA_CONFIGURATION_AUTH`. Il contient uniquement l'audience publique et le chemin du cache. Aucune clé privée Google n'est nécessaire.

## 6. Vérifier

### Vérifications locales

```sh
cd serveur
composer install
php tests/authentification.php
php tests/verifier.php
```

Les tests d'authentification utilisent des signatures RSA éphémères et une base SQLite en mémoire. Ils vérifient notamment la signature, l'émetteur, l'audience, l'expiration, le nonce, les sessions et l'absence de fusion automatique par e-mail. Ils ne remplacent pas un essai avec un vrai compte Google et MariaDB.

### Essai réel sur iPhone

1. Compiler avec une équipe de signature autorisée et lancer l'app.
2. Dans Profil, toucher le bouton Google et sélectionner un utilisateur de test.
3. Vérifier l'ouverture du profil et la création d'un utilisateur/identité dans MariaDB.
4. Quitter puis relancer l'app : la session doit être revalidée auprès du serveur.
5. Se déconnecter puis se reconnecter : le même identifiant Google retrouve le même utilisateur.
6. Annuler la fenêtre Google : aucune session ni alerte d'erreur ne doit être créée.
7. Tester sans réseau : aucune connexion distante ne doit être simulée.

## Fonctionnement et limites de cette étape

- Routes : `POST auth-defi`, `POST auth-google`, `GET auth-session`, `POST auth-deconnexion`, via `index.php?route=...`.
- Un défi de cinq minutes est transmis comme nonce au SDK, puis consommé une seule fois après vérification de la signature Google.
- Les clés Google sont mises en cache une heure. Après une rotation exceptionnelle de clé, un jeton signé par une clé inconnue est refusé jusqu'au renouvellement du cache.
- La session Mintza dure 24 heures ; l'utilisateur se reconnecte ensuite avec Google. Il n'y a pas encore de renouvellement automatique.
- Le jeton est conservé uniquement dans le trousseau iOS ; seule son empreinte SHA-256 est stockée côté serveur.
- Les nouveaux comptes sont des apprenants. Les rôles sont lus depuis la base et ne sont pas choisis par le client.
- Le compte Google ne fusionne pas automatiquement avec un compte local de même e-mail. Les comptes locaux et les démonstrations restent utilisables.
- Les favoris, la progression et les modifications de profil restent locaux à ce stade. La connexion ne constitue pas une synchronisation de ces données.
- La déconnexion efface immédiatement la session locale et tente sa révocation serveur. Si l'iPhone est hors ligne, le jeton serveur expire au plus tard après 24 heures.
- Avant une publication, ajouter le parcours de suppression du compte et examiner les exigences App Store applicables à la connexion Google. Cette étape prépare un prototype testable, pas une publication automatique.

## Références

- Google : <https://developers.google.com/identity/sign-in/ios/start-integrating>
- Connexion SwiftUI : <https://developers.google.com/identity/sign-in/ios/sign-in>
- Validation serveur : <https://developers.google.com/identity/sign-in/ios/backend-auth>
- Bibliothèque PHP JWT : <https://github.com/googleapis/php-jwt>
