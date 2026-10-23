<?php
declare(strict_types=1);

function repondreEnJson(mixed $donnees, int $statut = 200): never
{
    // Encoder avant d'envoyer le statut pour pouvoir traiter une erreur JSON.
    $contenuJson = json_encode($donnees, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    http_response_code($statut);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo $contenuJson;
    exit;
}
