<?php
declare(strict_types=1);

// Ici se trouvent les lectures de données. Aucun affichage ni code HTTP.
function catalogueExemple(): array
{
    return json_decode(
        file_get_contents(__DIR__ . '/../donnees_exemple/catalogue.json'),
        true, 512, JSON_THROW_ON_ERROR
    );
}

function chercherLecons(): array
{
    if (modeDonnees() === 'demonstration') {
        $lignes = catalogueExemple()['lecons'];
    } else {
        $lignes = connexionBase()->query(
            'SELECT idLecon, titreLecon, niveauLecon, descriptionLecon, ordreLecon
             FROM Lecon ORDER BY ordreLecon, idLecon'
        )->fetchAll();
    }
    foreach ($lignes as &$ligne) {
        $ligne['idLecon'] = (int) $ligne['idLecon'];
        $ligne['ordreLecon'] = (int) $ligne['ordreLecon'];
    }
    return $lignes;
}

// null = leçon inexistante ; [] = leçon existante sans exercice.
function chercherExercices(int $identifiantLecon): ?array
{
    if (modeDonnees() === 'demonstration') {
        $donnees = catalogueExemple();
        if (!in_array($identifiantLecon, array_column($donnees['lecons'], 'idLecon'), true)) {
            return null;
        }
        $lignes = array_values(array_filter($donnees['exercices'],
            fn(array $ligne): bool => $ligne['idLecon'] === $identifiantLecon));
    } else {
        $connexion = connexionBase();
        $verification = $connexion->prepare('SELECT idLecon FROM Lecon WHERE idLecon = ?');
        $verification->execute([$identifiantLecon]);
        if ($verification->fetch() === false) {
            return null;
        }
        $requete = $connexion->prepare(
            'SELECT idExo, idLecon, typeExo, libelleExo, contenuExo,
                    reponseExo, explicationExo, ordreExo
             FROM Exercice WHERE idLecon = ? ORDER BY ordreExo, idExo'
        );
        $requete->execute([$identifiantLecon]);
        $lignes = $requete->fetchAll();
    }
    foreach ($lignes as &$ligne) {
        foreach (['idExo', 'idLecon', 'ordreExo'] as $cle) {
            $ligne[$cle] = (int) $ligne[$cle];
        }
        // JSON SQL -> objets JSON dans la réponse, sans double encodage.
        foreach (['contenuExo', 'reponseExo'] as $cle) {
            $ligne[$cle] = json_decode($ligne[$cle], false, 512, JSON_THROW_ON_ERROR);
        }
    }
    return $lignes;
}

function chercherCommercesValides(): array
{
    if (modeDonnees() === 'demonstration') {
        $lignes = array_values(array_filter(catalogueExemple()['commerces'],
            fn(array $ligne): bool => $ligne['statut'] === 'valide'));
    } else {
        $lignes = connexionBase()->query(
            "SELECT idCommerce, nomCommerce, categorie, adresse, ville,
                    latitude, longitude, descriptionCommerce, horaires, imageUrl, statut
             FROM Commerce WHERE statut = 'valide' ORDER BY idCommerce"
        )->fetchAll();
    }
    foreach ($lignes as &$ligne) {
        $ligne['idCommerce'] = (int) $ligne['idCommerce'];
        foreach (['latitude', 'longitude'] as $cle) {
            $ligne[$cle] = $ligne[$cle] === null ? null : (float) $ligne[$cle];
        }
    }
    return $lignes;
}
