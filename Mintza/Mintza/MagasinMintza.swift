import Foundation
import Combine
import Security

struct ErreurMintza: LocalizedError {
    let message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

protocol CoffreIdentifiants {
    func enregistrer(_ secret: String, pour id: UUID) throws
    func lire(pour id: UUID) throws -> String?
}

/// Les mots de passe du prototype restent dans le trousseau de cet appareil.
struct TrousseauMintza: CoffreIdentifiants {
    private func requete(_ id: UUID) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "mintza.comptes.locaux",
         kSecAttrAccount as String: id.uuidString]
    }
    func enregistrer(_ secret: String, pour id: UUID) throws {
        let attributs = [kSecValueData as String: Data(secret.utf8)]
        let resultat = SecItemUpdate(requete(id) as CFDictionary, attributs as CFDictionary)
        if resultat == errSecItemNotFound {
            var ajout = requete(id).merging(attributs) { _, valeur in valeur }
            ajout[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(ajout as CFDictionary, nil) == errSecSuccess else {
                throw ErreurMintza("Impossible d’enregistrer les identifiants dans le trousseau.")
            }
        } else if resultat != errSecSuccess {
            throw ErreurMintza("Le trousseau est indisponible. Réessayez après avoir déverrouillé l’appareil.")
        }
    }
    func lire(pour id: UUID) throws -> String? {
        var recherche = requete(id)
        recherche[kSecReturnData as String] = true
        recherche[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultat: CFTypeRef?
        let statut = SecItemCopyMatching(recherche as CFDictionary, &resultat)
        if statut == errSecItemNotFound { return nil }
        guard statut == errSecSuccess, let donnees = resultat as? Data else {
            throw ErreurMintza("Impossible de lire les identifiants sur cet appareil.")
        }
        return String(data: donnees, encoding: .utf8)
    }
}

@MainActor
final class MagasinMintza: ObservableObject {
    @Published private(set) var etat: EtatMintza
    @Published var erreurStockage: String?
    private let fichier: URL
    private let coffre: any CoffreIdentifiants
    private var lectureValide = true

    init(fichier: URL? = nil, coffre: (any CoffreIdentifiants)? = nil) {
        self.fichier = fichier ?? URL.documentsDirectory.appendingPathComponent("mintza-v1.json")
        self.coffre = coffre ?? TrousseauMintza()
        do {
            if FileManager.default.fileExists(atPath: self.fichier.path) {
                etat = try JSONDecoder().decode(EtatMintza.self, from: Data(contentsOf: self.fichier))
            } else { etat = EtatMintza() }
        } catch {
            etat = EtatMintza()
            lectureValide = false
            erreurStockage = "Les données locales ne peuvent pas être lues. Elles sont conservées sans modification. \(error.localizedDescription)"
        }
    }

    var profil: ProfilMintza? { etat.profils.first { $0.id == etat.session } }
    var estAdmin: Bool { profil?.role == .administrateur }
    var mesDemandes: [DemandeMintza] { etat.demandes.filter { $0.auteur == profil?.id }.sorted { $0.date > $1.date } }
    var mesCommerces: [CommerceMintza] { etat.commerces.filter { $0.proprietaire == profil?.id && profil != nil } }
    var nombreLeconsTerminees: Int { (profil?.scores.count ?? 0) + (profil?.resultatsDistants?.count ?? 0) }
    var sansFaute: Bool {
        profil?.scores.values.contains(5) == true || profil?.resultatsDistants?.values.contains { $0.total > 0 && $0.bonnesReponses == $0.total } == true
    }
    var xp: Int {
        let anciens = profil?.scores.values.reduce(0, +) ?? 0
        let distants = profil?.resultatsDistants?.values.reduce(0) { $0 + $1.bonnesReponses } ?? 0
        return (anciens + distants) * 10
    }
    var activiteDuJour: Int { profil?.activites[Self.cleJour()] ?? 0 }
    static func cleJour(_ date: Date = Date()) -> String {
        let format = DateFormatter()
        format.calendar = Calendar(identifier: .gregorian)
        format.locale = Locale(identifier: "en_US_POSIX")
        format.dateFormat = "yyyy-MM-dd"
        return format.string(from: date)
    }

    private func enregistrer(_ nouvelEtat: EtatMintza) throws {
        guard lectureValide else { throw ErreurMintza("Sauvegarde désactivée pour préserver les données illisibles. Consultez le guide du projet.") }
        let donnees = try JSONEncoder().encode(nouvelEtat)
        try FileManager.default.createDirectory(at: fichier.deletingLastPathComponent(), withIntermediateDirectories: true)
        try donnees.write(to: fichier, options: .atomic)
        etat = nouvelEtat
    }

    static func emailValide(_ email: String) -> Bool {
        email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    func inscrire(prenom: String, nom: String, email: String, motDePasse: String, role: RoleMintza) throws {
        let adresse = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let prenom = prenom.trimmingCharacters(in: .whitespacesAndNewlines)
        let nom = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prenom.isEmpty, !nom.isEmpty, Self.emailValide(adresse) else { throw ErreurMintza("Renseignez votre prénom, votre nom et une adresse e-mail valide.") }
        guard motDePasse.count >= 8 else { throw ErreurMintza("Le mot de passe doit contenir au moins 8 caractères.") }
        guard role != .administrateur else { throw ErreurMintza("Ce rôle ne peut pas être créé par inscription.") }
        guard !etat.profils.contains(where: { $0.email == adresse }) else { throw ErreurMintza("Un compte utilise déjà cette adresse sur cet appareil.") }
        let nouveau = ProfilMintza(prenom: prenom, nom: nom, email: adresse, role: role)
        try coffre.enregistrer(motDePasse, pour: nouveau.id)
        var copie = etat
        copie.profils.append(nouveau)
        copie.session = nouveau.id
        try enregistrer(copie)
    }

    func connecter(email: String, motDePasse: String) throws {
        let adresse = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let compte = etat.profils.first(where: { $0.email == adresse && !$0.demonstration }),
              try coffre.lire(pour: compte.id) == motDePasse else { throw ErreurMintza("Adresse e-mail ou mot de passe incorrect.") }
        var copie = etat
        copie.session = compte.id
        try enregistrer(copie)
    }

    /// Accès explicite aux trois rôles du MVP, sans simuler une authentification distante.
    func ouvrirDemo(_ role: RoleMintza) throws {
        var copie = etat
        if let compte = copie.profils.first(where: { $0.demonstration && $0.role == role }) {
            copie.session = compte.id
        } else {
            let compte = ProfilMintza(prenom: "Démo", nom: role.rawValue, email: "", role: role, demonstration: true)
            copie.profils.append(compte)
            copie.session = compte.id
        }
        try enregistrer(copie)
    }

    func deconnecter() throws {
        var copie = etat
        copie.session = nil
        try enregistrer(copie)
    }

    func modifierProfil(prenom: String, nom: String, objectif: Int) throws {
        guard let index = etat.profils.firstIndex(where: { $0.id == etat.session }) else { throw ErreurMintza("Connectez-vous pour modifier votre profil.") }
        let prenom = prenom.trimmingCharacters(in: .whitespacesAndNewlines)
        let nom = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prenom.isEmpty, !nom.isEmpty, (1...5).contains(objectif) else { throw ErreurMintza("Renseignez votre nom et votre prénom.") }
        var copie = etat
        copie.profils[index].prenom = prenom
        copie.profils[index].nom = nom
        copie.profils[index].objectif = objectif
        try enregistrer(copie)
    }

    func terminer(_ lecon: LeconMintza, score: Int) throws {
        guard let index = etat.profils.firstIndex(where: { $0.id == etat.session }) else { return }
        guard (0...lecon.questions.count).contains(score) else { throw ErreurMintza("Score invalide.") }
        var copie = etat
        copie.profils[index].scores[lecon.id] = max(copie.profils[index].scores[lecon.id] ?? 0, score)
        copie.profils[index].activites[Self.cleJour(), default: 0] += 1
        try enregistrer(copie)
    }

    // Les profils du prototype sont locaux : aucune identité distante n’est inventée.
    func terminer(_ lecon: LeconDistante, score: Int, total: Int) throws {
        guard total > 0, (0...total).contains(score) else { throw ErreurMintza("Score invalide.") }
        guard let index = etat.profils.firstIndex(where: { $0.id == etat.session }) else { return }
        var copie = etat
        var resultats = copie.profils[index].resultatsDistants ?? [:]
        let cle = String(lecon.id)
        let nouveau = ResultatLeconDistante(bonnesReponses: score, total: total)
        if let ancien = resultats[cle], ancien.total == total {
            if score > ancien.bonnesReponses { resultats[cle] = nouveau }
        } else { resultats[cle] = nouveau }
        copie.profils[index].resultatsDistants = resultats
        copie.profils[index].activites[Self.cleJour(), default: 0] += 1
        try enregistrer(copie)
    }

    func basculerFavori(_ commerce: CommerceMintza) throws {
        guard let index = etat.profils.firstIndex(where: { $0.id == etat.session }) else { throw ErreurMintza("Connectez-vous pour enregistrer vos favoris.") }
        var copie = etat
        if copie.profils[index].favoris.contains(commerce.id) { copie.profils[index].favoris.remove(commerce.id) }
        else { copie.profils[index].favoris.insert(commerce.id) }
        try enregistrer(copie)
    }

    static func verifierCommerce(_ commerce: CommerceMintza) throws {
        let textes = [commerce.nom, commerce.adresse, commerce.ville, commerce.horaires, commerce.pratique]
        guard textes.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw ErreurMintza("Complétez le nom, l’adresse, la ville, les horaires et les informations de pratique.") }
        guard commerce.latitude.isFinite, commerce.longitude.isFinite,
              (43.30...43.65).contains(commerce.latitude), (-1.75 ... -1.25).contains(commerce.longitude) else {
            throw ErreurMintza("Placez le commerce dans le secteur Bayonne–Anglet–Biarritz (latitude 43,30 à 43,65 ; longitude −1,75 à −1,25).")
        }
    }

    func soumettre(_ commerce: CommerceMintza, miseAJour: Bool) throws {
        guard let profil, profil.role == .commercant || estAdmin else { throw ErreurMintza("Un profil commerçant est nécessaire.") }
        try Self.verifierCommerce(commerce)
        guard !etat.demandes.contains(where: { $0.commerce.id == commerce.id && $0.statut == .attente }) else { throw ErreurMintza("Une demande est déjà en attente pour cette fiche.") }
        if !miseAJour && etat.commerces.contains(where: { $0.id == commerce.id }) {
            throw ErreurMintza("Ce commerce est déjà publié. Utilisez la modification de fiche.")
        }
        if miseAJour {
            guard let original = etat.commerces.first(where: { $0.id == commerce.id }), original.proprietaire == profil.id || estAdmin else { throw ErreurMintza("Cette fiche ne peut pas être modifiée par votre compte.") }
        }
        var fiche = commerce
        if !miseAJour { fiche.proprietaire = profil.id; fiche.demonstration = profil.demonstration }
        var copie = etat
        copie.demandes.append(DemandeMintza(commerce: fiche, auteur: profil.id, miseAJour: miseAJour))
        try enregistrer(copie)
    }

    func moderer(_ id: UUID, accepter: Bool, motif: String) throws {
        guard estAdmin else { throw ErreurMintza("Accès réservé à l’administration de démonstration.") }
        guard let index = etat.demandes.firstIndex(where: { $0.id == id && $0.statut == .attente }) else { throw ErreurMintza("Cette demande a déjà été traitée.") }
        let motif = motif.trimmingCharacters(in: .whitespacesAndNewlines)
        guard accepter || !motif.isEmpty else { throw ErreurMintza("Indiquez un motif de refus pour le commerçant.") }
        var copie = etat
        let demande = copie.demandes[index]
        if accepter {
            try Self.verifierCommerce(demande.commerce)
            if demande.miseAJour {
                guard let fiche = copie.commerces.firstIndex(where: { $0.id == demande.commerce.id }) else { throw ErreurMintza("La fiche a été retirée. Refusez cette demande devenue obsolète.") }
                copie.commerces[fiche] = demande.commerce
            } else { copie.commerces.append(demande.commerce) }
        }
        copie.demandes[index].statut = accepter ? .validee : .refusee
        copie.demandes[index].motif = motif
        try enregistrer(copie)
    }

    func modifierCommerce(_ commerce: CommerceMintza) throws {
        guard estAdmin, let index = etat.commerces.firstIndex(where: { $0.id == commerce.id }) else { throw ErreurMintza("Fiche introuvable ou accès non autorisé.") }
        guard !etat.demandes.contains(where: { $0.commerce.id == commerce.id && $0.statut == .attente }) else { throw ErreurMintza("Traitez la demande en attente avant de modifier cette fiche.") }
        try Self.verifierCommerce(commerce)
        var copie = etat
        copie.commerces[index] = commerce
        try enregistrer(copie)
    }

    func retirerCommerce(_ id: UUID) throws {
        guard estAdmin else { throw ErreurMintza("Accès réservé à l’administration.") }
        var copie = etat
        copie.commerces.removeAll { $0.id == id }
        for index in copie.profils.indices { copie.profils[index].favoris.remove(id) }
        for index in copie.demandes.indices where copie.demandes[index].commerce.id == id && copie.demandes[index].statut == .attente {
            copie.demandes[index].statut = .refusee
            copie.demandes[index].motif = "La fiche a été retirée de la carte par l’administration."
        }
        try enregistrer(copie)
    }
}
