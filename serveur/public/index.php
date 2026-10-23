<?php
// Seul ce dossier public doit être accessible par le serveur web.
declare(strict_types=1);
ini_set('display_errors', '0');
require_once __DIR__ . '/../sources/reponse.php';
require_once __DIR__ . '/../sources/base_de_donnees.php';
require_once __DIR__ . '/../sources/acces_donnees/catalogue.php';
require_once __DIR__ . '/../sources/controleurs/catalogue.php';

try {
    $route = $_GET['route'] ?? 'sante';
    if (!is_string($route)) {
        repondreEnJson(['erreur' => 'Route invalide.'], 400);
    }
    if (!in_array($route, ['sante', 'lecons', 'exercices', 'commerces'], true)) {
        repondreEnJson(['erreur' => 'Route introuvable.'], 404);
    }
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
        header('Allow: GET');
        repondreEnJson(['erreur' => 'Méthode non autorisée.'], 405);
    }
    // La route sante teste PHP, pas la disponibilité de MariaDB.
    if ($route === 'sante') {
        repondreEnJson(['statut' => 'ok', 'application' => 'Mintza', 'mode' => modeDonnees()]);
    }
    match ($route) {
        'lecons' => listerLecons(),
        'exercices' => listerExercices(),
        'commerces' => listerCommerces(),
    };
} catch (PDOException $erreur) {
    error_log('Mintza : erreur SQL, code ' . $erreur->getCode());
    repondreEnJson(['erreur' => 'Base indisponible ou schéma non importé.'], 503);
} catch (Throwable $erreur) {
    error_log('Mintza : erreur interne de type ' . get_class($erreur));
    repondreEnJson(['erreur' => 'Erreur interne. Vérifier la configuration du serveur.'], 500);
}
