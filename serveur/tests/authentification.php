<?php
declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../sources/authentification.php';

use Firebase\JWT\JWT;

$nombre = 0;
function verifier(bool $condition, string $message): void
{
    global $nombre;
    if (!$condition) { throw new RuntimeException($message); }
    $nombre++;
}
function doitRefuser(callable $action, string $message): void
{
    try { $action(); }
    catch (ErreurAuthentification) { verifier(true, $message); return; }
    throw new RuntimeException('Acceptation indue : ' . $message);
}
function base64url(string $valeur): string { return rtrim(strtr(base64_encode($valeur), '+/', '-_'), '='); }

// Clés éphémères de test : aucun compte Google ni secret réel n'est nécessaire.
$privee = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
$details = openssl_pkey_get_details($privee);
$cles = ['keys' => [[
    'kty' => 'RSA', 'alg' => 'RS256', 'use' => 'sig', 'kid' => 'test',
    'n' => base64url($details['rsa']['n']), 'e' => base64url($details['rsa']['e']),
]]];
$audience = 'test.apps.googleusercontent.com';
$nonce = bin2hex(random_bytes(32));
$base = ['iss' => 'https://accounts.google.com', 'aud' => $audience, 'sub' => 'google-123',
    'nonce' => $nonce, 'iat' => time(), 'exp' => time() + 300,
    'email' => 'test@example.com', 'email_verified' => true];
$signer = static fn (array $preuve): string => JWT::encode($preuve, $privee, 'RS256', 'test');
$valider = static fn (array $preuve): object => verifierPreuveConnexion($signer($preuve), 'google', $audience, $nonce, $cles);
verifier($valider($base)->sub === 'google-123', 'Preuve valide');
foreach ([
    ['aud' => 'autre-client'], ['iss' => 'https://attaquant.example'], ['nonce' => 'autre-nonce'],
    ['exp' => time() - 1], ['iat' => time() + 120], ['iat' => time() - 601],
    ['sub' => ''], ['sub' => 123], ['email_verified' => false, 'nonce' => 'mauvais'],
] as $modification) {
    doitRefuser(static fn () => $valider(array_replace($base, $modification)), 'Claims invalides');
}
foreach (['exp', 'iat', 'nonce', 'aud', 'sub', 'iss'] as $champ) {
    $preuve = $base;
    unset($preuve[$champ]);
    doitRefuser(static fn () => $valider($preuve), 'Claim manquant : ' . $champ);
}
$fausseCle = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
doitRefuser(static fn () => verifierPreuveConnexion(JWT::encode($base, $fausseCle, 'RS256', 'test'), 'google', $audience, $nonce, $cles), 'Fausse signature');
doitRefuser(static fn () => verifierPreuveConnexion(JWT::encode($base, str_repeat('x', 64), 'HS256', 'test'), 'google', $audience, $nonce, $cles), 'Confusion algorithme');
doitRefuser(static fn () => verifierPreuveConnexion('invalide', 'google', $audience, $nonce, $cles), 'Jeton mal formé');
doitRefuser(static fn () => audienceConnexion('apple', ['googleAudience' => $audience]), 'Fournisseur non activé');
doitRefuser(static fn () => audienceConnexion('google', []), 'Configuration absente');

$jetonTest = str_repeat('a', 64);
verifier(jetonSessionDepuisEntetes(['HTTP_AUTHORIZATION' => 'Bearer ' . $jetonTest], []) === $jetonTest, 'En-tête serveur');
verifier(jetonSessionDepuisEntetes([], ['authorization' => 'Bearer ' . $jetonTest]) === $jetonTest, 'En-tête Apache');
verifier(jetonSessionDepuisEntetes(['REDIRECT_HTTP_AUTHORIZATION' => 'Bearer ' . $jetonTest], []) === $jetonTest, 'En-tête redirigé');
doitRefuser(static fn () => jetonSessionDepuisEntetes([], ['Authorization' => 'Bearer invalide']), 'En-tête invalide');


// SQLite exerce les requêtes et les transactions sans modifier la base de la VM.
$bdd = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$bdd->exec('CREATE TABLE Utilisateur (idUtilisateur INTEGER PRIMARY KEY AUTOINCREMENT, pseudo TEXT, email TEXT, roleUtilisateur TEXT)');
$bdd->exec('CREATE TABLE IdentiteConnexion (fournisseur TEXT, sujet TEXT, idUtilisateur INTEGER, PRIMARY KEY (fournisseur, sujet))');
$bdd->exec('CREATE TABLE SessionConnexion (empreinte TEXT PRIMARY KEY, idUtilisateur INTEGER, expiration INTEGER)');
$bdd->exec('CREATE TABLE DefiConnexion (identifiant TEXT PRIMARY KEY, fournisseur TEXT, nonce TEXT, adresse TEXT, creation INTEGER, expiration INTEGER)');
$defi = creerDefiConnexion($bdd, 'google', '127.0.0.1');
$preuve = (object) array_replace($base, ['nonce' => $defi['nonce']]);
$session = ouvrirSessionConnexion($bdd, 'google', $defi['identifiant'], $preuve);
verifier($session['profil']['roleUtilisateur'] === 'apprenant', 'Rôle par défaut');
verifier(utilisateurSessionConnexion($bdd, $session['jeton']) === $session['profil']['idUtilisateur'], 'Session utilisable');
verifier($bdd->query('SELECT empreinte FROM SessionConnexion')->fetchColumn() !== $session['jeton'], 'Jeton stocké sous forme d’empreinte');
doitRefuser(static fn () => ouvrirSessionConnexion($bdd, 'google', $defi['identifiant'], $preuve), 'Rejeu du défi');
$autre = creerDefiConnexion($bdd, 'google', '127.0.0.1');
$reconnexion = ouvrirSessionConnexion($bdd, 'google', $autre['identifiant'], (object) array_replace($base, ['nonce' => $autre['nonce']]));
verifier($session['profil']['idUtilisateur'] === $reconnexion['profil']['idUtilisateur'], 'Identité permanente');
$autre = creerDefiConnexion($bdd, 'google', '127.0.0.1');
$compteDistinct = ouvrirSessionConnexion($bdd, 'google', $autre['identifiant'], (object) array_replace($base, ['nonce' => $autre['nonce'], 'sub' => 'autre-google']));
verifier($session['profil']['idUtilisateur'] !== $compteDistinct['profil']['idUtilisateur'], 'Même email : aucun rattachement automatique');
$autre = creerDefiConnexion($bdd, 'google', '127.0.0.1');
$sansEmail = ouvrirSessionConnexion($bdd, 'google', $autre['identifiant'], (object) array_replace($base, ['nonce' => $autre['nonce'], 'sub' => 'non-verifie', 'email_verified' => false]));
verifier($sansEmail['profil']['email'] === null, 'Email non vérifié ignoré');
doitRefuser(static fn () => utilisateurSessionConnexion($bdd, str_repeat('0', 64)), 'Session inconnue');
$bdd->prepare('UPDATE SessionConnexion SET expiration = ? WHERE empreinte = ?')->execute([time() - 1, hash('sha256', $session['jeton'])]);
doitRefuser(static fn () => utilisateurSessionConnexion($bdd, $session['jeton']), 'Session expirée');
$bdd->prepare('DELETE FROM SessionConnexion WHERE empreinte = ?')->execute([hash('sha256', $reconnexion['jeton'])]);
doitRefuser(static fn () => utilisateurSessionConnexion($bdd, $reconnexion['jeton']), 'Session révoquée');
$autre = creerDefiConnexion($bdd, 'google', '127.0.0.1');
$bdd->prepare('UPDATE DefiConnexion SET expiration = ? WHERE identifiant = ?')->execute([time() - 1, $autre['identifiant']]);
doitRefuser(static fn () => ouvrirSessionConnexion($bdd, 'google', $autre['identifiant'], (object) array_replace($base, ['nonce' => $autre['nonce']])), 'Défi expiré');
for ($i = 0; $i < 20; $i++) { creerDefiConnexion($bdd, 'google', '192.0.2.1'); }
doitRefuser(static fn () => creerDefiConnexion($bdd, 'google', '192.0.2.1'), 'Limite de tentatives');
// Vérifier le routage HTTP sans ouvrir de port ni contacter une base réelle.
function verifierRoute(string $route, string $methode, bool $https, int $attendu): void
{
    $entree = realpath(__DIR__ . '/../public/index.php');
    $code = 'putenv("MINTZA_MODE=demonstration");'
        . '$_GET = ' . var_export(['route' => $route], true) . ';'
        . '$_SERVER = ' . var_export(['REQUEST_METHOD' => $methode, 'HTTPS' => $https ? 'on' : 'off', 'SERVER_PORT' => $https ? 443 : 80], true) . ';'
        . 'register_shutdown_function(function () { echo "\\nSTATUT=" . http_response_code(); });'
        . 'require ' . var_export($entree, true) . ';';
    $processus = proc_open([PHP_BINARY, '-r', $code], [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $tuyaux);
    if (!is_resource($processus)) { throw new RuntimeException('Processus PHP indisponible.'); }
    fclose($tuyaux[0]);
    $sortie = stream_get_contents($tuyaux[1]);
    $erreurs = stream_get_contents($tuyaux[2]);
    fclose($tuyaux[1]);
    fclose($tuyaux[2]);
    $codeSortie = proc_close($processus);
    verifier($codeSortie === 0 && str_ends_with($sortie, 'STATUT=' . $attendu), 'Route ' . $route . ' : ' . $sortie . $erreurs);
}
verifierRoute('auth-google', 'POST', false, 426);
verifierRoute('auth-defi', 'GET', true, 405);
verifierRoute('auth-session', 'POST', true, 405);
verifierRoute('auth-google', 'POST', true, 503);
verifierRoute('auth-apple', 'POST', true, 404);
echo "$nombre vérifications d’authentification réussies.\n";
