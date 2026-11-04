<?php
declare(strict_types=1);

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;

final class ErreurAuthentification extends RuntimeException
{
    public function __construct(string $message, public readonly int $statut = 401)
    {
        parent::__construct($message);
    }
}

function configurationAuthentification(): array
{
    $chemin = getenv('MINTZA_CONFIGURATION_AUTH') ?: '/etc/mintza/authentification.php';
    if (!is_readable($chemin)) {
        throw new ErreurAuthentification('La connexion est momentanément indisponible.', 503);
    }
    $configuration = require $chemin;
    if (!is_array($configuration)) {
        throw new RuntimeException('Configuration authentification invalide.');
    }
    return $configuration;
}

function audienceConnexion(string $fournisseur, array $configuration): string
{
    if (!in_array($fournisseur, ['google'], true)) {
        throw new ErreurAuthentification('Fournisseur invalide.', 400);
    }
    $audience = $configuration[$fournisseur . 'Audience'] ?? '';
    if (!is_string($audience) || $audience === '') {
        throw new ErreurAuthentification('Ce mode de connexion n’est pas encore configuré.', 503);
    }
    return $audience;
}

function clesConnexion(string $fournisseur, array $configuration): array
{
    $url = match ($fournisseur) {
        'google' => 'https://www.googleapis.com/oauth2/v3/certs',
        default => throw new ErreurAuthentification('Fournisseur invalide.', 400),
    };
    $dossier = $configuration['cacheCles'] ?? '/var/cache/mintza';
    if (!is_string($dossier) || !is_dir($dossier) || !is_writable($dossier)) {
        throw new RuntimeException('Cache des clés non configuré.');
    }
    $fichier = $dossier . '/' . $fournisseur . '.json';
    if (is_file($fichier) && filemtime($fichier) > time() - 3600) {
        $cles = json_decode((string) file_get_contents($fichier), true);
        if (is_array($cles) && isset($cles['keys'])) { return $cles; }
    }
    $curl = curl_init($url);
    curl_setopt_array($curl, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 8,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_FOLLOWLOCATION => false,
        CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);
    $proxy = $configuration['proxyHttps'] ?? null;
    if ($proxy !== null && $proxy !== '') {
        if (!is_string($proxy) || !in_array(parse_url($proxy, PHP_URL_SCHEME), ['http', 'https'], true)
            || !parse_url($proxy, PHP_URL_HOST)) {
            throw new RuntimeException('Configuration du proxy HTTPS invalide.');
        }
        curl_setopt($curl, CURLOPT_PROXY, $proxy);
        curl_setopt($curl, CURLOPT_NOPROXY, '');
    }
    $contenu = curl_exec($curl);
    $statut = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    curl_close($curl);
    if (!is_string($contenu) || strlen($contenu) > 262144 || $statut !== 200) {
        throw new ErreurAuthentification('Le service de connexion est indisponible. Réessayez.', 503);
    }
    $cles = json_decode($contenu, true);
    if (!is_array($cles) || empty($cles['keys'])) {
        throw new ErreurAuthentification('Le service de connexion est indisponible. Réessayez.', 503);
    }
    $temporaire = tempnam($dossier, 'cles-');
    if ($temporaire === false) { throw new RuntimeException('Cache indisponible.'); }
    try {
        if (file_put_contents($temporaire, $contenu) === false || !rename($temporaire, $fichier)) {
            throw new RuntimeException('Écriture du cache impossible.');
        }
    } finally {
        if (is_file($temporaire)) { unlink($temporaire); }
    }
    return $cles;
}

function verifierPreuveConnexion(string $jeton, string $fournisseur, string $audience, string $nonce, array $cles): object
{
    if ($audience === '' || $nonce === '' || strlen($jeton) > 16384) {
        throw new ErreurAuthentification('Preuve de connexion invalide.');
    }
    // Seules les clés RSA de signature des URL officielles sont acceptées.
    $cles['keys'] = array_values(array_filter($cles['keys'] ?? [], static fn ($cle) =>
        is_array($cle) && ($cle['kty'] ?? '') === 'RSA'
        && ($cle['alg'] ?? 'RS256') === 'RS256' && ($cle['use'] ?? 'sig') === 'sig'));
    try {
        $preuve = JWT::decode($jeton, JWK::parseKeySet($cles, 'RS256'));
    } catch (Throwable) {
        throw new ErreurAuthentification('Preuve de connexion invalide ou expirée.');
    }
    $emetteurs = match ($fournisseur) {
        'google' => ['https://accounts.google.com', 'accounts.google.com'],
        default => [],
    };
    if (!in_array($preuve->iss ?? '', $emetteurs, true)
        || ($preuve->aud ?? null) !== $audience
        || !is_string($preuve->sub ?? null) || strlen($preuve->sub) < 1 || strlen($preuve->sub) > 255
        || !is_string($preuve->nonce ?? null) || !hash_equals($nonce, $preuve->nonce)
        || !is_int($preuve->exp ?? null) || $preuve->exp <= time()
        || !is_int($preuve->iat ?? null) || $preuve->iat > time() + 30 || $preuve->iat < time() - 600) {
        throw new ErreurAuthentification('Preuve de connexion invalide ou expirée.');
    }
    return $preuve;
}

function creerDefiConnexion(PDO $bdd, string $fournisseur, string $adresse): array
{
    $maintenant = time();
    $bdd->prepare('DELETE FROM DefiConnexion WHERE expiration <= ?')->execute([$maintenant]);
    $empreinteAdresse = hash('sha256', $adresse);
    $requete = $bdd->prepare('SELECT COUNT(*) FROM DefiConnexion WHERE adresse = ? AND creation > ?');
    $requete->execute([$empreinteAdresse, $maintenant - 60]);
    if ((int) $requete->fetchColumn() >= 20) {
        throw new ErreurAuthentification('Trop de tentatives. Réessayez dans une minute.', 429);
    }
    $defi = ['identifiant' => bin2hex(random_bytes(32)), 'nonce' => bin2hex(random_bytes(32))];
    $bdd->prepare('INSERT INTO DefiConnexion (identifiant, fournisseur, nonce, adresse, creation, expiration) VALUES (?, ?, ?, ?, ?, ?)')
        ->execute([$defi['identifiant'], $fournisseur, $defi['nonce'], $empreinteAdresse, $maintenant, $maintenant + 300]);
    return $defi;
}

function profilConnexion(PDO $bdd, int $identifiant): array
{
    $requete = $bdd->prepare('SELECT idUtilisateur, pseudo, email, roleUtilisateur FROM Utilisateur WHERE idUtilisateur = ?');
    $requete->execute([$identifiant]);
    $profil = $requete->fetch();
    if (!$profil) { throw new ErreurAuthentification('Compte introuvable.'); }
    $profil['idUtilisateur'] = (int) $profil['idUtilisateur'];
    return $profil;
}

function ouvrirSessionConnexion(PDO $bdd, string $fournisseur, string $identifiantDefi, object $preuve): array
{
    $bdd->beginTransaction();
    try {
        // Consommation atomique : une seule connexion peut utiliser ce défi.
        $requete = $bdd->prepare('DELETE FROM DefiConnexion WHERE identifiant = ? AND fournisseur = ? AND nonce = ? AND expiration > ?');
        $requete->execute([$identifiantDefi, $fournisseur, $preuve->nonce, time()]);
        if ($requete->rowCount() !== 1) { throw new ErreurAuthentification('Connexion expirée. Recommencez.'); }
        $requete = $bdd->prepare('SELECT idUtilisateur FROM IdentiteConnexion WHERE fournisseur = ? AND sujet = ?');
        $requete->execute([$fournisseur, $preuve->sub]);
        $id = $requete->fetchColumn();
        if ($id === false) {
            $email = null;
            if (in_array($preuve->email_verified ?? false, [true, 'true'], true)
                && is_string($preuve->email ?? null) && strlen($preuve->email) <= 150
                && filter_var($preuve->email, FILTER_VALIDATE_EMAIL)) { $email = $preuve->email; }
            // Un pseudo peut être choisi ensuite ; aucun nom transmis par le client n'est utilisé comme identité.
            $bdd->prepare("INSERT INTO Utilisateur (pseudo, email, roleUtilisateur) VALUES (?, ?, 'apprenant')")
                ->execute(['Apprenant', $email]);
            $id = (int) $bdd->lastInsertId();
            $bdd->prepare('INSERT INTO IdentiteConnexion (fournisseur, sujet, idUtilisateur) VALUES (?, ?, ?)')
                ->execute([$fournisseur, $preuve->sub, $id]);
        }
        $jeton = bin2hex(random_bytes(32));
        $expiration = time() + 86400;
        $bdd->prepare('DELETE FROM SessionConnexion WHERE expiration <= ?')->execute([time()]);
        $bdd->prepare('INSERT INTO SessionConnexion (empreinte, idUtilisateur, expiration) VALUES (?, ?, ?)')
            ->execute([hash('sha256', $jeton), $id, $expiration]);
        $profil = profilConnexion($bdd, (int) $id);
        $bdd->commit();
        return ['jeton' => $jeton, 'expiration' => $expiration, 'profil' => $profil];
    } catch (Throwable $erreur) {
        if ($bdd->inTransaction()) { $bdd->rollBack(); }
        throw $erreur;
    }
}

function utilisateurSessionConnexion(PDO $bdd, string $jeton): int
{
    if (!preg_match('/^[a-f0-9]{64}$/D', $jeton)) { throw new ErreurAuthentification('Reconnectez-vous.'); }
    $requete = $bdd->prepare('SELECT idUtilisateur FROM SessionConnexion WHERE empreinte = ? AND expiration > ?');
    $requete->execute([hash('sha256', $jeton), time()]);
    $id = $requete->fetchColumn();
    if ($id === false) { throw new ErreurAuthentification('Session expirée. Reconnectez-vous.'); }
    return (int) $id;
}

function jetonSessionDepuisEntetes(array $serveur, array $entetes): string
{
    $entete = $serveur['HTTP_AUTHORIZATION'] ?? $serveur['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if ($entete === '') {
        foreach ($entetes as $nom => $valeur) {
            if (is_string($nom) && strcasecmp($nom, 'Authorization') === 0) {
                $entete = $valeur;
                break;
            }
        }
    }
    if (!is_string($entete) || !preg_match('/^Bearer ([a-f0-9]{64})$/D', $entete, $groupes)) {
        throw new ErreurAuthentification('Reconnectez-vous.');
    }
    return $groupes[1];
}

function traiterAuthentification(string $route): never
{
    header('Cache-Control: no-store');
    if (($_SERVER['HTTPS'] ?? '') !== 'on' && (int) ($_SERVER['SERVER_PORT'] ?? 0) !== 443) {
        throw new ErreurAuthentification('La connexion nécessite HTTPS.', 426);
    }
    $methode = $route === 'auth-session' ? 'GET' : 'POST';
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== $methode) {
        header('Allow: ' . $methode);
        throw new ErreurAuthentification('Méthode non autorisée.', 405);
    }
    if (modeDonnees() !== 'bdd') { throw new ErreurAuthentification('La connexion nécessite la base utilisateurs.', 503); }
    $donnees = [];
    if ($methode === 'POST') {
        if (!str_starts_with(strtolower($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')) {
            throw new ErreurAuthentification('Format JSON requis.', 415);
        }
        $corps = file_get_contents('php://input', false, null, 0, 20001);
        if ($corps === false || strlen($corps) > 20000) { throw new ErreurAuthentification('Requête trop volumineuse.', 413); }
        $donnees = json_decode($corps, true);
        if (!is_array($donnees)) { throw new ErreurAuthentification('Requête invalide.', 400); }
    }
    $bdd = connexionBase();
    if (in_array($route, ['auth-session', 'auth-deconnexion'], true)) {
        $entetes = function_exists('getallheaders') ? getallheaders() : [];
        $jeton = jetonSessionDepuisEntetes($_SERVER, is_array($entetes) ? $entetes : []);
        if ($route === 'auth-deconnexion') {
            $bdd->prepare('DELETE FROM SessionConnexion WHERE empreinte = ?')->execute([hash('sha256', $jeton)]);
            repondreEnJson(['statut' => 'ok']);
        }
        repondreEnJson(profilConnexion($bdd, utilisateurSessionConnexion($bdd, $jeton)));
    }
    $configuration = configurationAuthentification();
    $fournisseur = $route === 'auth-defi' ? ($donnees['fournisseur'] ?? '') : substr($route, 5);
    if (!is_string($fournisseur)) { throw new ErreurAuthentification('Fournisseur invalide.', 400); }
    $audience = audienceConnexion($fournisseur, $configuration);
    if ($route === 'auth-defi') {
        repondreEnJson(creerDefiConnexion($bdd, $fournisseur, $_SERVER['REMOTE_ADDR'] ?? 'inconnue'));
    }
    $jeton = $donnees['jeton'] ?? null;
    $defi = $donnees['defi'] ?? null;
    if (!is_string($jeton) || !is_string($defi) || !preg_match('/^[a-f0-9]{64}$/D', $defi)) {
        throw new ErreurAuthentification('Requête invalide.', 400);
    }
    $requete = $bdd->prepare('SELECT nonce FROM DefiConnexion WHERE identifiant = ? AND fournisseur = ? AND expiration > ?');
    $requete->execute([$defi, $fournisseur, time()]);
    $nonce = $requete->fetchColumn();
    if (!is_string($nonce)) { throw new ErreurAuthentification('Connexion expirée. Recommencez.'); }
    $autoload = __DIR__ . '/../vendor/autoload.php';
    if (!is_file($autoload)) { throw new ErreurAuthentification('La connexion est momentanément indisponible.', 503); }
    require_once $autoload;
    $preuve = verifierPreuveConnexion($jeton, $fournisseur, $audience, $nonce, clesConnexion($fournisseur, $configuration));
    repondreEnJson(ouvrirSessionConnexion($bdd, $fournisseur, $defi, $preuve));
}
