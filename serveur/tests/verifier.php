<?php
declare(strict_types=1);
// Contrôles en processus séparés : aucun serveur ni base nécessaires.
$pointEntree = realpath(__DIR__ . '/../public/index.php');
$programme = <<<'CODE'
parse_str($argv[1], $_GET);
$_SERVER['REQUEST_METHOD'] = $argv[2];
register_shutdown_function(function () { fwrite(STDERR, (string) (http_response_code() ?: 200)); });
require $argv[3];
CODE;
function envoyerRequete(string $requete, string $methode = 'GET', string $mode = 'demonstration'): array
{
    global $programme, $pointEntree;
    $processus = proc_open([PHP_BINARY, '-r', $programme, $requete, $methode, $pointEntree],
        [1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $flux, null,
        array_merge(getenv(), ['MINTZA_MODE' => $mode]));
    $corps = stream_get_contents($flux[1]);
    $erreur = stream_get_contents($flux[2]);
    fclose($flux[1]); fclose($flux[2]);
    $codeSortie = proc_close($processus);
    if ($codeSortie !== 0) { throw new RuntimeException($erreur); }
    preg_match('/(\d{3})$/', $erreur, $correspondance);
    return [(int) ($correspondance[1] ?? 0), json_decode($corps, true, 512, JSON_THROW_ON_ERROR)];
}
function verifier(bool $valeur, string $libelle): void
{
    if (!$valeur) { throw new RuntimeException('ÉCHEC : ' . $libelle); }
    echo 'OK — ' . $libelle . PHP_EOL;
}
[$statut, $corps] = envoyerRequete('route=sante');
verifier($statut === 200 && $corps['mode'] === 'demonstration', 'PHP disponible sans base');
[$statut, $corps] = envoyerRequete('route=lecons');
verifier($statut === 200 && count($corps) === 6 && is_int($corps[0]['idLecon']), '6 leçons et identifiants numériques');
$nombre = 0; $types = [];
for ($identifiant = 1; $identifiant <= 6; $identifiant++) {
    [$statut, $corps] = envoyerRequete('route=exercices&idLecon=' . $identifiant);
    verifier($statut === 200 && count($corps) === 4, '4 exercices pour la leçon ' . $identifiant);
    foreach ($corps as $exercice) {
        verifier(is_array($exercice['contenuExo']) && is_array($exercice['reponseExo']), 'JSON décodé pour ' . $exercice['idExo']);
        $nombre++; $types[$exercice['typeExo']] = true;
    }
}
verifier($nombre === 24 && count($types) === 7, '24 exercices couvrant 7 types');
[$statut, $corps] = envoyerRequete('route=commerces');
verifier($statut === 200 && count($corps) === 4 && !in_array(5, array_column($corps, 'idCommerce')), 'commerce en attente masqué');
verifier(is_float($corps[0]['latitude']), 'coordonnées numériques pour Swift');
foreach (['', '&idLecon=-1', '&idLecon=1 OR 1=1', '&idLecon[]=1', '&idLecon=4294967296'] as $suffixe) {
    verifier(envoyerRequete('route=exercices' . $suffixe)[0] === 400, 'paramètre refusé : ' . $suffixe);
}
verifier(envoyerRequete('route=exercices&idLecon=999')[0] === 404, 'leçon absente');
verifier(envoyerRequete('route=inconnue')[0] === 404, 'route absente');
verifier(envoyerRequete('route[]=sante')[0] === 400, 'route de mauvais type');
verifier(envoyerRequete('route=lecons', 'POST')[0] === 405, 'méthode refusée');
verifier(envoyerRequete('route=sante', 'GET', 'invalide')[0] === 500, 'configuration invalide');
echo "Tests terminés. Mode MariaDB non testé ici.\n";
