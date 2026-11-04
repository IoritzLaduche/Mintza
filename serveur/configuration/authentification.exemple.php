<?php
// Copier hors du dépôt : /etc/mintza/authentification.php.
// Identifiants publics. Aucun secret Google nécessaire pour vérifier un ID token.
return [
    'googleAudience' => '252488088117-f28spjt0bsuvdvbk095l0i6524j08cnv.apps.googleusercontent.com', // ID du client OAuth de type Application Web (serveur).
    'cacheCles' => '/var/cache/mintza', // Dossier privé, accessible en écriture par PHP.
];
