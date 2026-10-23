-- Mintza : création de la base et des six tables de la maquette.
-- Les tables existantes sont conservées ; ce script ne modifie pas leur structure.
-- Compatible avec le schéma attendu par exercices_60_a1_c2.sql.
CREATE DATABASE IF NOT EXISTS mintza_maquette
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mintza_maquette;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Utilisateur (
    idUtilisateur INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pseudo VARCHAR(50) NOT NULL,
    email VARCHAR(150),
    roleUtilisateur ENUM('apprenant','commercant','administrateur') NOT NULL DEFAULT 'apprenant',
    niveauUtilisateur ENUM('A1','A2','B1','B2','C1','C2') NOT NULL DEFAULT 'A1',
    xp INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Lecon (
    idLecon INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titreLecon VARCHAR(150) NOT NULL,
    niveauLecon ENUM('A1','A2','B1','B2','C1','C2') NOT NULL,
    descriptionLecon TEXT,
    ordreLecon INT UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Exercice (
    idExo INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    idLecon INT UNSIGNED NOT NULL,
    typeExo ENUM('qcm','vrai_faux','phrase_trou','dialogue','association','ordre_mots','comprehension_ecrite') NOT NULL,
    libelleExo TEXT NOT NULL,
    contenuExo JSON NOT NULL,
    reponseExo JSON NOT NULL,
    explicationExo TEXT,
    ordreExo INT UNSIGNED NOT NULL DEFAULT 1,
    FOREIGN KEY (idLecon) REFERENCES Lecon(idLecon),
    UNIQUE (idLecon, ordreExo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Progression (
    idUtilisateur INT UNSIGNED NOT NULL,
    idLecon INT UNSIGNED NOT NULL,
    meilleurScore TINYINT UNSIGNED NOT NULL DEFAULT 0,
    terminee BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (idUtilisateur, idLecon),
    FOREIGN KEY (idUtilisateur) REFERENCES Utilisateur(idUtilisateur),
    FOREIGN KEY (idLecon) REFERENCES Lecon(idLecon),
    CHECK (meilleurScore BETWEEN 0 AND 100),
    CHECK (terminee IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Commerce (
    idCommerce INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    idProprietaire INT UNSIGNED,
    nomCommerce VARCHAR(150) NOT NULL,
    categorie VARCHAR(50) NOT NULL,
    adresse VARCHAR(255),
    ville VARCHAR(100) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    descriptionCommerce TEXT,
    horaires VARCHAR(255),
    imageUrl VARCHAR(500),
    statut ENUM('en_attente','valide','refuse') NOT NULL DEFAULT 'en_attente',
    motifRefus VARCHAR(255),
    FOREIGN KEY (idProprietaire) REFERENCES Utilisateur(idUtilisateur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS Favori (
    idUtilisateur INT UNSIGNED NOT NULL,
    idCommerce INT UNSIGNED NOT NULL,
    PRIMARY KEY (idUtilisateur, idCommerce),
    FOREIGN KEY (idUtilisateur) REFERENCES Utilisateur(idUtilisateur),
    FOREIGN KEY (idCommerce) REFERENCES Commerce(idCommerce)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
