-- À appliquer à la base mintza_maquette existante, après 01_creer_base.sql.
-- Aucune donnée existante n'est supprimée. Ne pas fusionner les comptes par e-mail.
USE mintza_maquette;

CREATE TABLE IF NOT EXISTS IdentiteConnexion (
    fournisseur VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    sujet VARBINARY(255) NOT NULL,
    idUtilisateur INT UNSIGNED NOT NULL,
    PRIMARY KEY (fournisseur, sujet),
    FOREIGN KEY (idUtilisateur) REFERENCES Utilisateur(idUtilisateur) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS SessionConnexion (
    empreinte CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
    idUtilisateur INT UNSIGNED NOT NULL,
    expiration BIGINT NOT NULL,
    FOREIGN KEY (idUtilisateur) REFERENCES Utilisateur(idUtilisateur) ON DELETE CASCADE,
    INDEX (expiration)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS DefiConnexion (
    identifiant CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
    fournisseur VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    nonce CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    adresse CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    creation BIGINT NOT NULL,
    expiration BIGINT NOT NULL,
    INDEX (adresse, creation),
    INDEX (expiration)
) ENGINE=InnoDB;
