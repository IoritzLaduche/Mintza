<?php
declare(strict_types=1);

function modeDonnees(): string
{
    $mode = getenv('MINTZA_MODE') ?: 'demonstration';
    if (!in_array($mode, ['demonstration', 'bdd'], true)) {
        throw new RuntimeException('Mode inconnu.');
    }
    return $mode;
}

function connexionBase(): PDO
{
    // Les identifiants SQL restent hors du dossier public et hors de Git.
    $chemin = getenv('MINTZA_CONFIGURATION_BDD') ?: '/etc/mintza/base_de_donnees.php';
    if (!is_readable($chemin)) {
        throw new RuntimeException('Configuration SQL absente.');
    }
    $configuration = require $chemin;
    if (!is_array($configuration)) {
        throw new RuntimeException('Configuration SQL invalide.');
    }
    foreach (['chaineConnexion', 'utilisateur', 'motDePasse'] as $cle) {
        if (!isset($configuration[$cle]) || !is_string($configuration[$cle])) {
            throw new RuntimeException('Configuration SQL incomplète.');
        }
    }
    return new PDO($configuration['chaineConnexion'], $configuration['utilisateur'], $configuration['motDePasse'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
}
