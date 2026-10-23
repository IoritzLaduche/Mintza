<?php
declare(strict_types=1);

// Le contrôleur vérifie la demande, appelle les données et répond en JSON.
function listerLecons(): never
{
    repondreEnJson(chercherLecons());
}

function listerExercices(): never
{
    $valeurBrute = $_GET['idLecon'] ?? null;
    if (!is_string($valeurBrute) || !preg_match('/^[1-9][0-9]*$/D', $valeurBrute)
        || strlen($valeurBrute) > 10 || (float) $valeurBrute > 4294967295) {
        repondreEnJson(['erreur' => 'idLecon doit être un entier positif valide.'], 400);
    }
    $lignes = chercherExercices((int) $valeurBrute);
    if ($lignes === null) {
        repondreEnJson(['erreur' => 'Leçon introuvable.'], 404);
    }
    repondreEnJson($lignes);
}

function listerCommerces(): never
{
    repondreEnJson(chercherCommercesValides());
}
