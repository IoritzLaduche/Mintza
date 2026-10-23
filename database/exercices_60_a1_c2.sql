-- Mintza : 6 nouvelles leçons, 60 exercices, 10 par niveau de A1 à C2.
-- Import unique : une réexécution ajoutera de nouvelles leçons et dupliquera le contenu.
-- Niveaux indicatifs ; contenus pédagogiques à relire avant publication.
-- Référence linguistique : [Euskaltzaindia, grammaire](https://www.euskaltzaindia.eus/dok/iker_jagon_tegiak/83272-2.pdf).
-- Référence pour omen : [L. Zubeldia, Euskera](https://euskera-ikerketa.euskaltzaindia.eus/index.php/euskera/es/article/view/250).
USE mintza_maquette;
SET NAMES utf8mb4;
SET @mode_sql_initial = @@SESSION.sql_mode;
SET SESSION sql_mode = IF(
    FIND_IN_SET('NO_BACKSLASH_ESCAPES', @mode_sql_initial) > 0,
    @mode_sql_initial,
    CONCAT_WS(',', NULLIF(@mode_sql_initial, ''), 'NO_BACKSLASH_ESCAPES')
);

START TRANSACTION;
SET @ordre_lecon = (SELECT COALESCE(MAX(ordreLecon), 0) FROM Lecon);

-- A1
SET @ordre_lecon = @ordre_lecon + 1;
INSERT INTO Lecon (titreLecon, niveauLecon, descriptionLecon, ordreLecon)
VALUES ('Premiers mots dans les commerces', 'A1', 'Saluer, se présenter, commander simplement et comprendre des informations courtes.', @ordre_lecon);
SET @id_lecon = LAST_INSERT_ID();

INSERT INTO Exercice
    (idLecon, typeExo, libelleExo, contenuExo, reponseExo, explicationExo, ordreExo)
VALUES
    (
        @id_lecon, 'qcm',
        'Que signifie « Eskerrik asko » ?',
        '{"choix":[{"id":"a","texte":"Bonjour"},{"id":"b","texte":"Merci"},{"id":"c","texte":"À demain"}]}',
        '{"choixId":"b"}',
        '« Eskerrik asko » permet de remercier quelqu’un.', 1
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète la présentation à la première personne.',
        '{"phrase":"Ni Iker ___.","choix":[{"id":"a","texte":"naiz"},{"id":"b","texte":"zara"},{"id":"c","texte":"dira"}]}',
        '{"choixId":"a"}',
        '« Ni » signifie « je ». Pour se présenter, on dit « Ni Iker naiz ».', 2
    ),
    (
        @id_lecon, 'dialogue',
        'Choisis la réponse qui commande de l’eau.',
        '{"situation":"Tu es au café et tu souhaites boire de l’eau.","replique":"Zer nahi duzu?","choix":[{"id":"a","texte":"Kontua, mesedez."},{"id":"b","texte":"Kafea, mesedez."},{"id":"c","texte":"Ura, mesedez."}]}',
        '{"choixId":"c"}',
        '« Ura » signifie « l’eau ». « Kontua » désigne ici l’addition et « kafea » le café.', 3
    ),
    (
        @id_lecon, 'association',
        'Associe chaque produit à sa traduction.',
        '{"gauche":[{"id":"g1","texte":"ogia"},{"id":"g2","texte":"esnea"},{"id":"g3","texte":"sagarra"}],"droite":[{"id":"d1","texte":"la pomme"},{"id":"d2","texte":"le pain"},{"id":"d3","texte":"le lait"}]}',
        '{"paires":[{"gaucheId":"g1","droiteId":"d2"},{"gaucheId":"g2","droiteId":"d3"},{"gaucheId":"g3","droiteId":"d1"}]}',
        '« Ogia » signifie « le pain », « esnea » « le lait » et « sagarra » « la pomme ».', 4
    ),
    (
        @id_lecon, 'vrai_faux',
        'La traduction proposée est-elle correcte ?',
        '{"affirmation":"« Hiru sagar » signifie « trois pommes »."}',
        '{"valeur":true}',
        '« Hiru » est le nombre trois ; « sagar » désigne une pomme.', 5
    ),
    (
        @id_lecon, 'ordre_mots',
        'Ordonne les étapes de cet échange : saluer, se présenter, puis prendre congé.',
        '{"mots":[{"id":"m1","texte":"Ni Ane naiz."},{"id":"m2","texte":"Agur!"},{"id":"m3","texte":"Kaixo!"}]}',
        '{"ordre":["m3","m1","m2"]}',
        'On commence par « Kaixo! », puis on se présente avec « Ni Ane naiz. », avant de prendre congé avec « Agur! ». On ordonne ici les étapes de l’échange, pas les mots d’une phrase.', 6
    ),
    (
        @id_lecon, 'comprehension_ecrite',
        'Quel jour le café est-il fermé ?',
        '{"texte":"Kaixo! Ni Maialen naiz. Kafetegi txiki bat dut Baionan. Goizean kafea eta ogia saltzen ditut. Astelehenetik larunbatera irekita dago kafetegia. Igandean itxita dago. Ongi etorri!","choix":[{"id":"a","texte":"Le lundi"},{"id":"b","texte":"Le samedi"},{"id":"c","texte":"Le dimanche"}]}',
        '{"choixId":"c"}',
        '« Igandean itxita dago » indique que le café est fermé le dimanche.', 7
    ),
    (
        @id_lecon, 'qcm',
        'Quelle question demande le prix d’un objet ?',
        '{"choix":[{"id":"a","texte":"Zenbat balio du?"},{"id":"b","texte":"Non dago?"},{"id":"c","texte":"Zer ordu da?"}]}',
        '{"choixId":"a"}',
        '« Zenbat balio du? » demande combien coûte un objet. Les autres questions portent sur le lieu et sur l’heure.', 8
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète la phrase avec la forme correspondant à « nous ».',
        '{"phrase":"Gu ikasleak ___.","choix":[{"id":"a","texte":"zarete"},{"id":"b","texte":"gara"},{"id":"c","texte":"da"}]}',
        '{"choixId":"b"}',
        '« Gu » signifie « nous » et s’emploie ici avec « gara » : « Nous sommes élèves ».', 9
    ),
    (
        @id_lecon, 'dialogue',
        'Demande à ton interlocuteur de répéter.',
        '{"situation":"Tu n’as pas compris ce que le commerçant vient de dire.","replique":"Beste zerbait nahi duzu?","choix":[{"id":"a","texte":"Barkatu, errepikatuko duzu, mesedez?"},{"id":"b","texte":"Bai, bi sagar nahi ditut."},{"id":"c","texte":"Ez, eskerrik asko."}]}',
        '{"choixId":"a"}',
        'La première réponse demande poliment une répétition. Les deux autres répondent directement à la question sans signaler l’incompréhension.', 10
    );

-- A2
SET @ordre_lecon = @ordre_lecon + 1;
INSERT INTO Lecon (titreLecon, niveauLecon, descriptionLecon, ordreLecon)
VALUES ('Se débrouiller au quotidien', 'A2', 'Comprendre des horaires, acheter, demander une autre taille et raconter une action simple.', @ordre_lecon);
SET @id_lecon = LAST_INSERT_ID();

INSERT INTO Exercice
    (idLecon, typeExo, libelleExo, contenuExo, reponseExo, explicationExo, ordreExo)
VALUES
    (
        @id_lecon, 'qcm',
        'Où se trouve le magasin dans « Denda bankuaren ondoan dago » ?',
        '{"choix":[{"id":"a","texte":"Derrière la banque"},{"id":"b","texte":"À côté de la banque"},{"id":"c","texte":"Loin de la banque"}]}',
        '{"choixId":"b"}',
        '« Bankuaren ondoan » signifie « à côté de la banque ».', 1
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète le récit d’un achat effectué hier.',
        '{"phrase":"Atzo liburu bat erosi ___.","choix":[{"id":"a","texte":"dut"},{"id":"b","texte":"zait"},{"id":"c","texte":"nuen"}]}',
        '{"choixId":"c"}',
        '« Atzo » situe l’action hier. « Erosi nuen » est la forme passée attendue ici pour « j’ai acheté ».', 2
    ),
    (
        @id_lecon, 'dialogue',
        'Réponds en précisant que vous êtes deux.',
        '{"situation":"Tu entres au restaurant avec une amie.","replique":"Zenbat lagun zarete?","choix":[{"id":"a","texte":"Bi lagun gara."},{"id":"b","texte":"Bietan etorriko gara."},{"id":"c","texte":"Bi kafe nahi ditugu."}]}',
        '{"choixId":"a"}',
        '« Bi lagun gara » indique que vous êtes deux personnes. « Bietan » indique deux heures, et deux cafés ne précisent pas le nombre de convives.', 3
    ),
    (
        @id_lecon, 'association',
        'Associe chaque expression à sa traduction.',
        '{"gauche":[{"id":"g1","texte":"joan-etorriko txartela"},{"id":"g2","texte":"ordainagiria"},{"id":"g3","texte":"aldatzeko gela"}],"droite":[{"id":"d1","texte":"la cabine d’essayage"},{"id":"d2","texte":"le billet aller-retour"},{"id":"d3","texte":"le reçu"}]}',
        '{"paires":[{"gaucheId":"g1","droiteId":"d2"},{"gaucheId":"g2","droiteId":"d3"},{"gaucheId":"g3","droiteId":"d1"}]}',
        'Les trois expressions désignent respectivement un billet aller-retour, un reçu et une cabine d’essayage.', 4
    ),
    (
        @id_lecon, 'vrai_faux',
        'L’affirmation correspond-elle à l’horaire annoncé ?',
        '{"affirmation":"Ordutegia: « Asteartean eta ostegunean bakarrik irekitzen dugu ». Beraz, astelehenean ere irekita dago denda."}',
        '{"valeur":false}',
        '« Bakarrik » signifie « seulement ». Le magasin ouvre le mardi et le jeudi, donc pas le lundi.', 5
    ),
    (
        @id_lecon, 'ordre_mots',
        'Remets ces étapes dans l’ordre indiqué par les marqueurs temporels.',
        '{"mots":[{"id":"m1","texte":"Azkenik, etxera itzuli naiz."},{"id":"m2","texte":"Lehenik, ogia aukeratu dut."},{"id":"m3","texte":"Ondoren, ogia ordaindu dut."}]}',
        '{"ordre":["m2","m3","m1"]}',
        '« Lehenik » annonce la première étape, « ondoren » la suivante et « azkenik » la dernière : choisir, payer, puis rentrer.', 6
    ),
    (
        @id_lecon, 'comprehension_ecrite',
        'Où Ane et Jon doivent-ils se retrouver samedi ?',
        '{"texte":"Larunbatean azokara joango gara. Lehen, kafetegiaren aurrean elkartzen ginen, baina aste honetan kafetegia itxita dago. Horregatik, geltokiaren aurrean elkartuko gara, goizeko hamarretan. Ane autobusez etorriko da, eta Jon oinez. Ekarri poltsa bat, fruta eta barazkiak erosteko. Euria egiten badu, azokara joango gara hala ere, eraikin baten barruan dagoelako.","choix":[{"id":"a","texte":"Devant le café"},{"id":"b","texte":"À l’intérieur du marché"},{"id":"c","texte":"Devant la gare"}]}',
        '{"choixId":"c"}',
        'Le point de rencontre a changé : « geltokiaren aurrean » signifie « devant la gare ». Le café est fermé cette semaine.', 7
    ),
    (
        @id_lecon, 'qcm',
        'Dans « Gaur euria ari du; horregatik, autobusez joango naiz », pourquoi la personne prend-elle le bus ?',
        '{"choix":[{"id":"a","texte":"Parce qu’il pleut"},{"id":"b","texte":"Parce que le bus est gratuit"},{"id":"c","texte":"Parce qu’elle est en retard"}]}',
        '{"choixId":"a"}',
        '« Euria ari du » signifie qu’il pleut. « Horregatik » relie cette cause au choix du bus.', 8
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète la commande de deux sandwichs.',
        '{"phrase":"Bi ogitarteko nahi ___.","choix":[{"id":"a","texte":"dut"},{"id":"b","texte":"ditut"},{"id":"c","texte":"zara"}]}',
        '{"choixId":"b"}',
        '« Bi ogitarteko » est un objet pluriel. À la première personne du singulier, on utilise ici « ditut ».', 9
    ),
    (
        @id_lecon, 'dialogue',
        'Demande une taille plus petite.',
        '{"situation":"Tu essaies un manteau, mais il est trop grand.","replique":"Nola duzu berokia?","choix":[{"id":"a","texte":"Garestiegia da. Merkeagorik baduzue?"},{"id":"b","texte":"Kolore hau ez zait gustatzen. Urdina baduzue?"},{"id":"c","texte":"Handiegia da. Txikiagoa baduzue?"}]}',
        '{"choixId":"c"}',
        '« Handiegia » signifie « trop grand » et « txikiagoa » « plus petit ». Les autres réponses concernent le prix ou la couleur.', 10
    );

-- B1
SET @ordre_lecon = @ordre_lecon + 1;
INSERT INTO Lecon (titreLecon, niveauLecon, descriptionLecon, ordreLecon)
VALUES ('Expliquer et organiser ses échanges', 'B1', 'Exprimer une cause, organiser un rendez-vous et comprendre un récit de pratique linguistique.', @ordre_lecon);
SET @id_lecon = LAST_INSERT_ID();

INSERT INTO Exercice
    (idLecon, typeExo, libelleExo, contenuExo, reponseExo, explicationExo, ordreExo)
VALUES
    (
        @id_lecon, 'qcm',
        'Quel lien exprime « Autobusa galdu dudanez, oinez joango naiz » ?',
        '{"choix":[{"id":"a","texte":"Une condition encore incertaine"},{"id":"b","texte":"Une opposition entre deux opinions"},{"id":"c","texte":"La cause du déplacement à pied"}]}',
        '{"choixId":"c"}',
        'La terminaison « -nez » présente ici une cause : la personne ira à pied parce qu’elle a raté le bus.', 1
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète ce projet pour demain.',
        '{"phrase":"Bihar denbora badut, azokara ___.","choix":[{"id":"a","texte":"joango naiz"},{"id":"b","texte":"joan nintzen"},{"id":"c","texte":"joan zinen"}]}',
        '{"choixId":"a"}',
        'Le projet concerne demain et dépend du temps disponible : « joango naiz » exprime ici « j’irai ». Les autres formes renvoient au passé.', 2
    ),
    (
        @id_lecon, 'dialogue',
        'Propose de reporter le rendez-vous à onze heures.',
        '{"situation":"Tu devais retrouver une amie à dix heures, mais tu es occupé jusqu’à onze heures.","replique":"Bihar hamarretan elkartuko gara?","choix":[{"id":"a","texte":"Bai, hamarretan ondo datorkit."},{"id":"b","texte":"Hamarretan ezin dut. Hamaiketan elkartuko gara?"},{"id":"c","texte":"Bihar ezin dut egun osoan."}]}',
        '{"choixId":"b"}',
        'La deuxième réponse refuse dix heures et propose onze heures, sans annuler toute la journée.', 3
    ),
    (
        @id_lecon, 'association',
        'Associe chaque phrase à la relation qu’elle exprime.',
        '{"gauche":[{"id":"g1","texte":"Gaixorik nago; horregatik, etxean geratuko naiz."},{"id":"g2","texte":"Kafea gustatzen zait, baina gaur tea hartuko dut."},{"id":"g3","texte":"Lehenik, txartela erosi; ondoren, autobusera igo."}],"droite":[{"id":"d1","texte":"Une opposition"},{"id":"d2","texte":"Une succession d’actions"},{"id":"d3","texte":"Une conséquence"}]}',
        '{"paires":[{"gaucheId":"g1","droiteId":"d3"},{"gaucheId":"g2","droiteId":"d1"},{"gaucheId":"g3","droiteId":"d2"}]}',
        '« Horregatik » introduit une conséquence, « baina » une opposition et « lehenik / ondoren » une succession.', 4
    ),
    (
        @id_lecon, 'vrai_faux',
        'L’affirmation correspond-elle au récit ?',
        '{"affirmation":"« Euria egin arren, bisita gidatua egin genuen ». Beraz, bisita ez zen bertan behera geratu euriagatik."}',
        '{"valeur":true}',
        '« Euria egin arren » signifie « malgré la pluie ». La visite a bien eu lieu et n’a donc pas été annulée à cause de celle-ci.', 5
    ),
    (
        @id_lecon, 'qcm',
        'Quelle phrase rapporte correctement les paroles « Bihar itxita egongo gara » du commerçant ?',
        '{"choix":[{"id":"a","texte":"Dendariak esan du bihar itxita egongo direla."},{"id":"b","texte":"Dendariak esan du atzo itxita egon zirela."},{"id":"c","texte":"Dendariak galdetu du bihar irekita egongo diren."}]}',
        '{"choixId":"a"}',
        'La première phrase conserve l’annonce d’une fermeture pour demain et transforme les paroles en discours rapporté. Les autres changent le temps ou transforment l’annonce en question.', 6
    ),
    (
        @id_lecon, 'comprehension_ecrite',
        'Qu’est-ce qui aide principalement Leire à prendre confiance ?',
        '{"texte":"Leire duela hiru hilabete hasi zen euskara ikasten. Hasieran, dendara sartzean, frantsesez egiten zuen beti, akatsak egiteko beldur zelako. Irakasleak helburu txiki bat proposatu zion: egunero galdera bat euskaraz egitea. Orain, ogia erosten duenean, prezioa galdetzen du eta dendaria agurtzen du. Dendariak badaki Leire ikasten ari dela, eta poliki erantzuten dio. Hitz bat ulertzen ez badu, beste modu batean azaltzeko eskatzen dio Leirek. Oraindik ez ditu elkarrizketa luzeak erraz jarraitzen, baina gero eta lasaiago hitz egiten du. Larunbatean lagun batekin azokara joango da, beste saltzaile batzuekin ere praktikatzeko.","choix":[{"id":"a","texte":"Éviter les commerces tant qu’elle fait des erreurs"},{"id":"b","texte":"Pratiquer de petits échanges avec un interlocuteur patient"},{"id":"c","texte":"Mémoriser une longue conversation avant chaque achat"}]}',
        '{"choixId":"b"}',
        'Leire pratique une question quotidienne, reçoit des réponses lentes et demande des reformulations. Le texte ne dit pas qu’elle attend de parler parfaitement ou mémorise un dialogue entier.', 7
    ),
    (
        @id_lecon, 'qcm',
        'Dans « Poltsa bat ekarri dut, erosketak eramateko », à quoi sert le sac ?',
        '{"choix":[{"id":"a","texte":"À emballer un cadeau déjà offert"},{"id":"b","texte":"À éviter de faire les courses"},{"id":"c","texte":"À transporter les achats"}]}',
        '{"choixId":"c"}',
        '« Erosketak eramateko » exprime le but : transporter les achats.', 8
    ),
    (
        @id_lecon, 'phrase_trou',
        'Le commerçant vient de me donner le reçu. Complète la phrase.',
        '{"phrase":"Dendariak ordainagiria eman ___.","choix":[{"id":"a","texte":"diot"},{"id":"b","texte":"dit"},{"id":"c","texte":"dio"}]}',
        '{"choixId":"b"}',
        '« Eman dit » signifie ici « il ou elle me l’a donné ». Le destinataire est « moi » ; « dio » désignerait une autre personne.', 9
    ),
    (
        @id_lecon, 'dialogue',
        'Préviens de ton retard en proposant une solution.',
        '{"situation":"Ton bus est en retard. Tu arriveras vers 18 h 15 au lieu de 18 h.","replique":"Seietan hemen egongo zara?","choix":[{"id":"a","texte":"Autobusa atzeratu da. Sei eta laurdenetan iritsiko naiz; itxaron dezakezu?"},{"id":"b","texte":"Bai, seietan iritsiko naiz, arazorik gabe."},{"id":"c","texte":"Ez naiz joango, gaur ez baitut zurekin elkartu nahi."}]}',
        '{"choixId":"a"}',
        'La première réponse explique le retard, donne une nouvelle heure et demande si l’autre personne peut attendre.', 10
    );

-- B2
SET @ordre_lecon = @ordre_lecon + 1;
INSERT INTO Lecon (titreLecon, niveauLecon, descriptionLecon, ordreLecon)
VALUES ('Argumenter dans les situations du quotidien', 'B2', 'Nuancer une opinion, comprendre les conditions d’une offre et reformuler un échange.', @ordre_lecon);
SET @id_lecon = LAST_INSERT_ID();

INSERT INTO Exercice
    (idLecon, typeExo, libelleExo, contenuExo, reponseExo, explicationExo, ordreExo)
VALUES
    (
        @id_lecon, 'qcm',
        'Quelle reformulation conserve le sens de « Prezioa igo den arren, bezeroek hemen erosten jarraitzen dute » ?',
        '{"choix":[{"id":"a","texte":"Prezioa igo da; hala ere, bezeroek hemen erosten dute oraindik."},{"id":"b","texte":"Bezeroek hemen erosten dute prezioa jaitsi delako."},{"id":"c","texte":"Prezioa igo bada, bezeroek ez dute hemen erosiko."}]}',
        '{"choixId":"a"}',
        '« -en arren » exprime une concession : la hausse du prix n’empêche pas les clients de continuer à acheter ici.', 1
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète avec une expression qui ajoute un avantage.',
        '{"phrase":"Denda honek, bertako produktuak saltzeaz ___, etxera eramateko zerbitzua ere eskaintzen du.","choix":[{"id":"a","texte":"ordez"},{"id":"b","texte":"gain"},{"id":"c","texte":"gero"}]}',
        '{"choixId":"b"}',
        '« Saltzeaz gain » signifie « en plus de vendre ». La phrase additionne la vente de produits locaux et le service de livraison.', 2
    ),
    (
        @id_lecon, 'dialogue',
        'Demande un remboursement en rappelant les conditions applicables.',
        '{"situation":"La boutique accepte le remboursement sous sept jours si le produit est intact et accompagné du reçu. Tu l’as acheté hier, il est intact et tu as le reçu.","replique":"Zertan lagun zaitzaket?","choix":[{"id":"a","texte":"Produktua duela hilabete erosi nuen, baina berdin zait zuen epea."},{"id":"b","texte":"Ez daukat ordainagiririk, baina dirua itzultzera behartuta zaudete."},{"id":"c","texte":"Atzo erosi nuen, erabili gabe dago eta ordainagiria ekarri dut. Dirua itzuliko didazue?"}]}',
        '{"choixId":"c"}',
        'La troisième réponse expose les trois conditions remplies et formule la demande. Les autres réponses contredisent la situation.', 3
    ),
    (
        @id_lecon, 'association',
        'Associe chaque phrase à sa fonction dans un argument.',
        '{"gauche":[{"id":"g1","texte":"Batetik, merkeagoa da; bestetik, etxetik gertu dago."},{"id":"g2","texte":"Hala ere, ordutegia ez da guztientzat egokia."},{"id":"g3","texte":"Laburbilduz, abantailak eta mugak kontuan hartu behar dira."}],"droite":[{"id":"d1","texte":"Laburpena egitea"},{"id":"d2","texte":"Bi arrazoi aurkeztea"},{"id":"d3","texte":"Aurreko ideiari muga jartzea"}]}',
        '{"paires":[{"gaucheId":"g1","droiteId":"d2"},{"gaucheId":"g2","droiteId":"d3"},{"gaucheId":"g3","droiteId":"d1"}]}',
        '« Batetik / bestetik » organise deux raisons, « hala ere » apporte une réserve et « laburbilduz » annonce une synthèse.', 4
    ),
    (
        @id_lecon, 'vrai_faux',
        'L’interprétation découle-t-elle de la phrase ?',
        '{"affirmation":"« Bezero guztiek ez dute txartelarekin ordaintzen » esateak bezero bakar batek ere ez duela txartelik erabiltzen esan nahi du."}',
        '{"valeur":false}',
        '« Pas tous » ne signifie pas « aucun ». La phrase nie que tous les clients paient par carte, sans affirmer que personne ne le fait.', 5
    ),
    (
        @id_lecon, 'comprehension_ecrite',
        'Quelle réponse l’association apporte-t-elle aux difficultés des débutants ?',
        '{"texte":"Auzoko elkarteak ostegunero elkarrizketa saioak antolatzen ditu kafetegi batean. Hasieran, parte-hartzaileek nahi zuten gaiaz hitz egiten zuten, baina hasiberri batzuek zailtasunak zituzten elkarrizketari jarraitzeko. Arduradunek ez zuten taldea mailaren arabera banatu nahi, esperientzia desberdineko pertsonak elkarrekin aritzea baliagarria iruditzen zitzaielako. Horren ordez, saio bakoitzaren hasieran gai bat aurkeztea eta hitz lagungarri batzuk mahai gainean jartzea erabaki zuten. Gainera, txandak errespetatzeko eta zalantzak lasai galdetzeko eskatu zuten. Hilabete geroago, hasiberriek errazago parte hartzen zutela esan zuten. Hala ere, neurriak ez zuen arazo guztiak konpondu: zenbaitek oraindik azkarregi hitz egiten zuen. Hurrengo saioetan, moderatzaile batek erritmoa zainduko du. Helburua ez da elkarrizketa erabat kontrolatzea, baizik eta denek hitza hartzeko aukera izatea, euren maila edozein dela ere.","choix":[{"id":"a","texte":"Saioak maila aurreratukoentzat soilik uztea."},{"id":"b","texte":"Laguntza eta hitz egiteko txandak antolatzea, taldea banatu gabe."},{"id":"c","texte":"Elkarrizketa guztiak buruz ikasteko testu bihurtzea."}]}',
        '{"choixId":"b"}',
        'L’association conserve le groupe mixte et ajoute des thèmes, du vocabulaire, des tours de parole puis une modération du rythme. Elle ne réserve pas les séances aux personnes avancées.', 6
    ),
    (
        @id_lecon, 'qcm',
        'Que signifie « Aldez aurretik erreserbatu ezean, ezin dugu mahaia bermatu » ?',
        '{"choix":[{"id":"a","texte":"La réservation garantit que le restaurant sera vide."},{"id":"b","texte":"Il est interdit de réserver à l’avance."},{"id":"c","texte":"Sans réservation préalable, la disponibilité d’une table n’est pas garantie."}]}',
        '{"choixId":"c"}',
        '« Erreserbatu ezean » signifie « si vous ne réservez pas ». La phrase ne dit pas qu’il est toujours impossible d’obtenir une table sans réservation.', 7
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète la proposition qui précise de quel livre il s’agit.',
        '{"phrase":"Atzo erosi ___ liburua euskaraz dago.","choix":[{"id":"a","texte":"nuen"},{"id":"b","texte":"nuela"},{"id":"c","texte":"nuenez"}]}',
        '{"choixId":"a"}',
        '« Atzo erosi nuen liburua » signifie « le livre que j’ai acheté hier ». La proposition relative précède le nom « liburua ».', 8
    ),
    (
        @id_lecon, 'dialogue',
        'Exprime une réserve tout en proposant un compromis.',
        '{"situation":"Ton groupe souhaite commencer les rencontres à 17 h. Plusieurs personnes travaillent jusqu’à 18 h.","replique":"Hemendik aurrera bostetan hasiko gara. Ados?","choix":[{"id":"a","texte":"Ados, ordutegi hori guztientzat ezin hobea da."},{"id":"b","texte":"Ulertzen dut proposamena, baina batzuek seietara arte egiten dute lan. Sei eta erdietan hastea aztertuko dugu?"},{"id":"c","texte":"Ez dut proposamena entzun nahi; ez dago eztabaidatzeko ezer."}]}',
        '{"choixId":"b"}',
        'La deuxième réponse reconnaît la proposition, explique sa limite et propose une heure qui tient compte des personnes concernées.', 9
    ),
    (
        @id_lecon, 'qcm',
        'Dans « Denda berria ez da merkeena; nolanahi ere, arreta ona eskaintzen du », quel rôle joue « nolanahi ere » ?',
        '{"choix":[{"id":"a","texte":"Il prouve que le magasin est finalement le moins cher."},{"id":"b","texte":"Il explique pourquoi les prix ont baissé."},{"id":"c","texte":"Il présente un aspect positif qui reste valable malgré la réserve sur les prix."}]}',
        '{"choixId":"c"}',
        '« Nolanahi ere » signifie ici « quoi qu’il en soit ». La qualité de l’accueil est mise en avant sans annuler la remarque sur les prix.', 10
    );

-- C1
SET @ordre_lecon = @ordre_lecon + 1;
INSERT INTO Lecon (titreLecon, niveauLecon, descriptionLecon, ordreLecon)
VALUES ('Nuancer son propos et évaluer une information', 'C1', 'Identifier les réserves, distinguer information rapportée et certitude, et adapter son registre.', @ordre_lecon);
SET @id_lecon = LAST_INSERT_ID();

INSERT INTO Exercice
    (idLecon, typeExo, libelleExo, contenuExo, reponseExo, explicationExo, ordreExo)
VALUES
    (
        @id_lecon, 'qcm',
        'Quelle reformulation respecte la prudence de « Baliteke ordutegi berriak parte-hartzea erraztea; oraingoz, ordea, ez dugu hori baieztatzeko adina datu » ?',
        '{"choix":[{"id":"a","texte":"Ordutegi berriak parte-hartzea handitu duela frogatuta dago."},{"id":"b","texte":"Ordutegi berria lagungarria izan daiteke, baina oraindik ezin dugu hori ziurtatu."},{"id":"c","texte":"Ordutegi berriak ez du inolako eraginik izango."}]}',
        '{"choixId":"b"}',
        'Le texte envisage un effet favorable tout en signalant que les données ne suffisent pas encore à l’affirmer. Il n’exclut pas cet effet et ne le présente pas comme prouvé.', 1
    ),
    (
        @id_lecon, 'phrase_trou',
        'Le locuteur rapporte une information entendue, sans la présenter comme une déduction personnelle. Choisis la particule adaptée.',
        '{"phrase":"Dendari batek esan dit: datorren astean azoka berria irekiko ___ dute.","choix":[{"id":"a","texte":"bide"},{"id":"b","texte":"ote"},{"id":"c","texte":"omen"}]}',
        '{"choixId":"c"}',
        '« Omen » marque ici une information rapportée. Il indique une source extérieure, sans signifier à lui seul que le locuteur juge l’information fausse ou douteuse.', 2
    ),
    (
        @id_lecon, 'dialogue',
        'Choisis une réponse formelle qui accueille l’idée sans promettre son adoption.',
        '{"situation":"Une commerçante propose de prolonger une expérimentation. Le bilan n’a pas encore été examiné.","replique":"Proba beste hiru hilabetez luzatzea proposatzen dizuegu.","choix":[{"id":"a","texte":"Eskerrik asko proposamenagatik. Emaitzak aztertu ondoren erantzungo dizuegu; oraingoz, ezin dugu luzapena baieztatu."},{"id":"b","texte":"Bai, luzapena erabakita dago, emaitzak aztertu ez baditugu ere."},{"id":"c","texte":"Ez dugu proposamena irakurriko, ez baitu inolako interesik."}]}',
        '{"choixId":"a"}',
        'La première réponse accuse réception, annonce l’examen des résultats et maintient clairement la décision ouverte.', 3
    ),
    (
        @id_lecon, 'association',
        'Associe chaque formulation à la nuance qu’elle introduit.',
        '{"gauche":[{"id":"g1","texte":"Datu hauek ikusita, litekeena da neurriak lagundu izana."},{"id":"g2","texte":"Neurria onuragarria izan da, nahiz eta ez dituen arazo guztiak konpondu."},{"id":"g3","texte":"Horrek ez du esan nahi emaitza bera beste auzoetan ere lortuko denik."}],"droite":[{"id":"d1","texte":"Ondorioa beste egoeretara zabaltzeari muga jartzea."},{"id":"d2","texte":"Onura aitortzea, muga bat ere onartuta."},{"id":"d3","texte":"Ebidentzian oinarritutako aukera bat planteatzea."}]}',
        '{"paires":[{"gaucheId":"g1","droiteId":"d3"},{"gaucheId":"g2","droiteId":"d2"},{"gaucheId":"g3","droiteId":"d1"}]}',
        'La première formulation avance une hypothèse appuyée sur des données ; la deuxième reconnaît une limite ; la troisième empêche une généralisation injustifiée.', 4
    ),
    (
        @id_lecon, 'vrai_faux',
        'L’affirmation interprète-t-elle correctement l’annonce ?',
        '{"affirmation":"« Ez da baztertzen zerbitzua larunbatetara zabaltzea ». Horrek esan nahi du datorren larunbatetik aurrera zerbitzua ziur eskainiko dela."}',
        '{"valeur":false}',
        '« Ez da baztertzen » laisse une possibilité ouverte. Cela ne constitue ni une décision ferme ni l’annonce d’une date de démarrage.', 5
    ),
    (
        @id_lecon, 'comprehension_ecrite',
        'Quelle conclusion rend le mieux compte de la portée du bilan ?',
        '{"texte":"Herriko merkatarien elkarteak euskarazko harrera sustatzeko proba bat egin du hamabi dendatan. Hiru hilabetez, langileek bezeroei euskaraz egin diete lehen agurra, eta nahi izan duten bezeroek hizkuntza horretan jarraitu dute. Amaieran, galdetegi bat banatu dute. Erantzun dutenen gehiengoak esperientzia atsegina izan dela esan du; batzuek, ordea, azaldu dute elkarrizketa luzeetan beste hizkuntza batera jo dutela. Elkarteak emaitzak baikortasunez hartu ditu, baina txostenean bi muga nabarmendu ditu. Batetik, galdetegia borondatez bete dute bezeroek, eta ez dakite erantzun ez dutenek zer iritzi duten. Bestetik, ez dute probaren aurreko erabilera neurtu; hortaz, ezin dute ziurtatu euskarazko elkarrizketak zenbat ugaritu diren. Hala ere, langileek adierazi dute lehen agurra euskaraz egiteak elkarrizketa hasteko zalantza gutxitu diela. Datorren aldian, behaketa sistematikoa eta elkarrizketa laburrak uztartu nahi dituzte, datu gehiago biltzeko. Helburua ez da emaitza onak zalantzan jartzea, baizik eta ondorioak ebidentziaren neurrira egokitzea. Izan ere, ekimen bat harrera onez hartzea eta eguneroko hizkuntza erabilera aldatzea ez dira gauza bera. Bereizketa hori argitzea ezinbestekotzat jo dute proba beste denda batzuetara zabaldu aurretik.","choix":[{"id":"a","texte":"Erantzunak baikorrak dira, baina ez dute erabileraren igoera neurtua frogatzen."},{"id":"b","texte":"Galdetegiak frogatu du bezero guztiek euskaraz hitz egiten dutela orain."},{"id":"c","texte":"Hasierako neurketarik ez dagoenez, langileen esperientziek ez dute inolako baliorik."}]}',
        '{"choixId":"a"}',
        'Le bilan signale une réception favorable, mais l’absence de mesure initiale et le caractère volontaire des réponses limitent les conclusions. Cela ne rend pas les témoignages inutiles.', 6
    ),
    (
        @id_lecon, 'qcm',
        'Quelle lecture respecte « Saltzaileek ez ezik, bezeroek ere proposamena babestu dute » ?',
        '{"choix":[{"id":"a","texte":"Saltzaileek proposamena babestu dute, baina bezeroek ez."},{"id":"b","texte":"Saltzaileek eta bezeroek proposamena babestu dute."},{"id":"c","texte":"Bezeroek proposamena babestu dute, saltzaileak izan ezik."}]}',
        '{"choixId":"b"}',
        '« Ez ezik ... ere » ajoute un deuxième groupe au premier : vendeurs et clients ont soutenu la proposition.', 7
    ),
    (
        @id_lecon, 'phrase_trou',
        'L’accord dépend d’une vérification préalable. Complète avec la conjonction conditionnelle.',
        '{"phrase":"Proposamena onartuko dugu, ___ gastuak aurrekontuaren barruan daudela egiaztatzen badugu.","choix":[{"id":"a","texte":"nahiz eta"},{"id":"b","texte":"izan ere"},{"id":"c","texte":"baldin eta"}]}',
        '{"choixId":"c"}',
        '« Baldin eta ... badugu » pose la condition : l’acceptation dépend de la vérification des dépenses. La phrase ne présente pas cette vérification comme déjà effectuée.', 8
    ),
    (
        @id_lecon, 'dialogue',
        'Demande une clarification sans attribuer à l’autre une opinion qu’il n’a pas exprimée.',
        '{"situation":"Le commerçant évalue une expérience et distingue l’intérêt du projet de ses conditions pratiques.","replique":"Ideia interesgarria da; ez dut, ordea, oraingo ordutegiarekin bideragarria ikusten.","choix":[{"id":"a","texte":"Beraz, euskararen aurka zaude eta ez duzu ezer egin nahi."},{"id":"b","texte":"Ordutegia da zure kezka nagusia? Zer aldaketak egingo luke proposamena bideragarriago?"},{"id":"c","texte":"Ados, esan duzu egungo ordutegia guztiz egokia dela."}]}',
        '{"choixId":"b"}',
        'La deuxième réponse vérifie l’interprétation et invite à préciser une amélioration possible. Les autres attribuent au commerçant une position contraire à ses paroles.', 9
    ),
    (
        @id_lecon, 'qcm',
        'Quel effet produit la phrase finale dans ce contexte : « Gaur ordutegia aldatuko zutela jakinarazi digute, bezeroak atean zain zeudenean. Garaiz abisatzea deitzen diote horri, antza » ?',
        '{"choix":[{"id":"a","texte":"La personne félicite sincèrement l’équipe pour son anticipation."},{"id":"b","texte":"La personne demande seulement la définition du mot ordutegi."},{"id":"c","texte":"La personne critique ironiquement le caractère tardif de l’annonce."}]}',
        '{"choixId":"c"}',
        'Le décalage entre les clients déjà devant la porte et « prévenir à temps » produit une critique ironique. « Antza » renforce ici la prise de distance du locuteur.', 10
    );

-- C2
SET @ordre_lecon = @ordre_lecon + 1;
INSERT INTO Lecon (titreLecon, niveauLecon, descriptionLecon, ordreLecon)
VALUES ('Interpréter les implicites avec précision', 'C2', 'Distinguer présupposés, engagements, portée des négations et limites d’une conclusion.', @ordre_lecon);
SET @id_lecon = LAST_INSERT_ID();

INSERT INTO Exercice
    (idLecon, typeExo, libelleExo, contenuExo, reponseExo, explicationExo, ordreExo)
VALUES
    (
        @id_lecon, 'qcm',
        'Quelle conclusion est autorisée par « Ez da nahikoa kartela euskaraz jartzea harrera euskaraz bermatzeko; horrek ez du esan nahi kartela jartzeak ezertarako balio ez duenik » ?',
        '{"choix":[{"id":"a","texte":"Kartela lagungarria izan daiteke, baina ez du bere kabuz harrera bermatzen."},{"id":"b","texte":"Kartela jartzea alferrikakoa dela dio testuak, beste neurririk egon edo ez."},{"id":"c","texte":"Kartela jarrita, euskarazko harrera bermatuta geratzen da."}]}',
        '{"choixId":"a"}',
        'Le texte refuse une condition suffisante, pas toute utilité du panneau. La seconde partie empêche justement de conclure que le panneau ne sert à rien.', 1
    ),
    (
        @id_lecon, 'phrase_trou',
        'Complète pour maintenir l’objection même en admettant l’argument précédent.',
        '{"phrase":"Onar dezagun neurriak ikusgarritasuna handitu duela. Hori onartuta ___, erabileran zer eragin izan duen argitu behar da.","choix":[{"id":"a","texte":"soilik"},{"id":"b","texte":"ere"},{"id":"c","texte":"arte"}]}',
        '{"choixId":"b"}',
        '« Hori onartuta ere » signifie « même en admettant cela ». La hausse de visibilité ne dispense pas de vérifier l’effet sur l’usage.', 2
    ),
    (
        @id_lecon, 'dialogue',
        'Réponds sans accepter la présupposition contestée, tout en restant disponible pour l’examen des faits.',
        '{"situation":"Dans cet échange, aucune enquête n’a établi que l’équipe a caché des informations.","replique":"Noiz onartuko duzue bezeroei informazioa ezkutatu zenietela?","choix":[{"id":"a","texte":"Bihar onartuko dugu, baina gaur ezin dugu esan."},{"id":"b","texte":"Ez dugu galderarik onartzen, eta ez dugu gertatutakoa aztertuko."},{"id":"c","texte":"Galderak frogatu gabeko zerbait aurresuposatzen du: informazioa ezkutatu genuela. Gertatutakoa aztertzeko prest gaude."}]}',
        '{"choixId":"c"}',
        'La question présuppose une dissimulation. La troisième réponse conteste explicitement ce présupposé sans refuser l’examen des faits ; elle ne prétend pas non plus prouver le contraire.', 3
    ),
    (
        @id_lecon, 'association',
        'Associe chaque énoncé à sa portée exacte, sans renforcer l’engagement du locuteur.',
        '{"gauche":[{"id":"g1","texte":"Neurria lagungarria izan daitekeela onartu du, ez ezinbestekoa dela."},{"id":"g2","texte":"Neurria onartu izanak ez du esan nahi haren alderdi guztiak babesten dituenik."},{"id":"g3","texte":"Neurria ez dela baztertu adierazi du; ez du esan onartu denik."}],"droite":[{"id":"d1","texte":"Aukera zabalik dago, baina ez dago aldeko erabaki baieztaturik."},{"id":"d2","texte":"Baliagarritasuna onartu da, ez beharrezkotasuna."},{"id":"d3","texte":"Erabaki orokorra eta xehetasun guztiekiko adostasuna bereizten dira."}]}',
        '{"paires":[{"gaucheId":"g1","droiteId":"d2"},{"gaucheId":"g2","droiteId":"d3"},{"gaucheId":"g3","droiteId":"d1"}]}',
        'Les distinctions portent sur utilité et nécessité, accord global et approbation de chaque détail, puis possibilité maintenue et décision effective. Aucune ne permet de renforcer la position exprimée.', 4
    ),
    (
        @id_lecon, 'vrai_faux',
        'L’inférence proposée est-elle justifiée ?',
        '{"affirmation":"« Ez dut ukatzen neurriak zenbait bezerori lagundu dienik; zalantzan jartzen dudana da denentzat egokia izatea ». Beraz, hizlariak ukatu egiten du neurriak inori lagundu dionik."}',
        '{"valeur":false}',
        'Le locuteur ne nie pas l’aide apportée à certains clients. Sa réserve porte sur l’adéquation pour tout le monde : la négation proposée inverse la portée de son propos.', 5
    ),
    (
        @id_lecon, 'comprehension_ecrite',
        'Quelle interprétation distingue correctement le constat, sa limite et la décision envisagée ?',
        '{"texte":"Kultur etxeko arduradunek jakinarazi dute euskarazko arreta eskaintzeko protokolo berriak ez duela kexarik eragin lehen bi hilabeteetan. Oharrean, ordea, berehala zehaztu dute kexarik jaso ez izana ezin dela erabiltzaile guztien gogobetetasunaren frogatzat hartu: baliteke deserosotasuna sentitu duten batzuek erreklamaziorik ez aurkeztea. Zehaztapen horrek eztabaida piztu du batzordean. Kide batek uste du halako oharrek alferrik ahultzen dutela ekimenaren irudia; beste batek, aldiz, gardentasunak konfiantza sendotzen duela erantzun dio. Txostenaren egileak argitu du ez duela porrotik iradoki nahi. Haren ustez, emaitza bat ez puztea ez da emaitza hori gutxiestea. Horregatik, protokoloa behin betiko ezarri aurretik, arreta jaso dutenen lagin bati iritzia eskatzea proposatu du, bai euskaraz jarraitu dutenei, bai beste hizkuntza bat aukeratu dutenei. Proposamenak ez du aldez aurretik ezartzen zein erantzun espero den; jasotako iritziek erakutsiko dute zer mantendu eta zer egokitu. Batzordeak datuak biltzea onartu du, baina protokoloa behin betiko ezartzeari buruzko erabakia hurrengo bilerara atzeratu du. Azken ohar horrek bereizketa bat gordetzen du: ebaluazioari ekiteko adostasuna ez da ebaluatu beharreko neurriaren behin betiko onespena.","choix":[{"id":"a","texte":"Kexarik ezak gogobetetasun osoa frogatzen du, eta batzordeak protokoloa behin betiko onartu du."},{"id":"b","texte":"Kexarik ezak ez du gogobetetasun osoa frogatzen; datuak biltzea onartu da, ez protokoloa behin betiko ezartzea."},{"id":"c","texte":"Egileak porrota egiaztatutzat jo du, eta batzordeak protokoloa bertan behera uztea erabaki du."}]}',
        '{"choixId":"b"}',
        'L’absence de plaintes est un constat limité, pas la preuve d’une satisfaction universelle. La décision concerne la collecte d’avis ; l’adoption définitive est reportée, sans constat de faillite ni abandon.', 6
    ),
    (
        @id_lecon, 'qcm',
        'Dans une discussion formelle, quelle reformulation respecte le degré d’engagement de « Ez litzateke zentzugabea izango proba luzatzea, betiere kostua mugatuta » ?',
        '{"choix":[{"id":"a","texte":"Proba luzatzea nahitaezkoa da, kostua edozein dela ere."},{"id":"b","texte":"Proba luzatzea zentzugabekeria da, kostua txikia izan arren."},{"id":"c","texte":"Proba luzatzea arrazoizko aukera izan liteke, kostuari muga jarrita."}]}',
        '{"choixId":"c"}',
        'La formulation négative atténuée présente une possibilité raisonnable assortie d’une condition. Elle ne constitue ni une obligation ni un rejet du prolongement.', 7
    ),
    (
        @id_lecon, 'phrase_trou',
        'Attribue explicitement l’information au rapport, sans exprimer une cause ou une concession.',
        '{"phrase":"Txostenak ___, hiru dendak soilik eskaini zuten zerbitzua proba osoan; datua oraindik egiaztatu behar dugu.","choix":[{"id":"a","texte":"dioenez"},{"id":"b","texte":"dioelako"},{"id":"c","texte":"dioen arren"}]}',
        '{"choixId":"a"}',
        '« Txostenak dioenez » attribue l’information au rapport. La suite maintient la nécessité d’une vérification ; « dioelako » exprimerait une cause et « dioen arren » une concession.', 8
    ),
    (
        @id_lecon, 'dialogue',
        'Corrige précisément la reformulation excessive de tes propos, sans nier ce que tu as annoncé.',
        '{"situation":"Tu as annoncé un examen du dossier avant vendredi, sans engagement sur la date de décision.","replique":"Beraz, ostiralerako eskaera onartuko duzuela agindu duzue.","choix":[{"id":"a","texte":"Ez dugu inoiz esan eskaera aztertuko dugunik."},{"id":"b","texte":"Ez dugu onarpena agindu: ostirala baino lehen eskaera aztertuko dugula esan dugu. Erabakiaren data ez dago zehaztuta."},{"id":"c","texte":"Bai, aztertzea eta onartzea gauza bera dira kasu honetan."}]}',
        '{"choixId":"b"}',
        'La deuxième réponse maintient l’engagement d’examen avant vendredi tout en refusant de le transformer en promesse d’acceptation ou en date de décision.', 9
    ),
    (
        @id_lecon, 'qcm',
        'Quelle lecture respecte la restriction dans « Ekimenak harrera ona izan duela diote elkarrizketatutako merkatariek; baieztapen hori haien esperientziari dagokio, eta ez da herritar guztien iritziaren neurketa » ?',
        '{"choix":[{"id":"a","texte":"Merkatarien testigantzak baliogabetzat jotzen dira, herritar guztiei galdetu ez zaielako."},{"id":"b","texte":"Harrera ona herritar guztien artean egiaztatu da, merkatariek hala esan dutelako."},{"id":"c","texte":"Testigantzek elkarrizketatutako merkatarien ikuspegia jasotzen dute, herritar guztiena ordezkatu gabe."}]}',
        '{"choixId":"c"}',
        'Le passage reconnaît une valeur aux témoignages tout en limitant leur représentativité. Il ne les annule pas et ne les transforme pas en mesure de l’opinion de tous les habitants.', 10
    );

COMMIT;
SET SESSION sql_mode = @mode_sql_initial;
