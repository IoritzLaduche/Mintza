import Foundation

enum RoleMintza: String, Codable, CaseIterable, Identifiable {
    case apprenant = "Apprenant", commercant = "Commerçant", administrateur = "Administrateur"
    var id: String { rawValue }
}

struct ProfilMintza: Codable, Identifiable {
    var id = UUID()
    var prenom: String
    var nom: String
    var email: String
    var role: RoleMintza
    var demonstration = false
    var objectif = 1
    var scores: [String: Int] = [:]
    var resultatsDistants: [String: ResultatLeconDistante]?
    var activites: [String: Int] = [:]
    var favoris: Set<UUID> = []
}

enum CategorieCommerce: String, Codable, CaseIterable, Identifiable {
    case cafe = "Café", restaurant = "Restaurant", boutique = "Boutique", culture = "Culture"
    var id: String { rawValue }
    var icone: String {
        switch self {
        case .cafe: "cup.and.saucer.fill"
        case .restaurant: "fork.knife"
        case .boutique: "basket.fill"
        case .culture: "books.vertical.fill"
        }
    }
}

struct CommerceMintza: Codable, Identifiable {
    var id = UUID()
    var proprietaire: UUID?
    var nom = ""
    var categorie: CategorieCommerce = .cafe
    var adresse = ""
    var ville = "Bayonne"
    var latitude = 43.4929
    var longitude = -1.4748
    var telephone = ""
    var horaires = ""
    var pratique = ""
    var demonstration = false

    static let exemples: [CommerceMintza] = [
        CommerceMintza(nom: "Kafe Mintza", categorie: .cafe, adresse: "Centre-ville (repère fictif)", ville: "Bayonne", latitude: 43.4905, longitude: -1.4750, horaires: "Lun–sam · 9 h–18 h", pratique: "Commandez un café et échangez quelques mots en euskara.", demonstration: true),
        CommerceMintza(nom: "Itsasoa", categorie: .restaurant, adresse: "Quartier des Halles (repère fictif)", ville: "Biarritz", latitude: 43.4804, longitude: -1.5612, horaires: "Mar–sam · 12 h–14 h / 19 h–22 h", pratique: "Entraînez-vous à saluer et à commander votre repas.", demonstration: true),
        CommerceMintza(nom: "Bertako Denda", categorie: .boutique, adresse: "Centre-ville (repère fictif)", ville: "Anglet", latitude: 43.4821, longitude: -1.5183, horaires: "Lun–sam · 10 h–19 h", pratique: "Posez une question simple sur les produits.", demonstration: true),
        CommerceMintza(nom: "Liburu Txokoa", categorie: .culture, adresse: "Petit Bayonne (repère fictif)", ville: "Bayonne", latitude: 43.4894, longitude: -1.4722, horaires: "Mar–sam · 10 h–18 h", pratique: "Découvrez des livres et présentez-vous en basque.", demonstration: true)
    ]
}

enum StatutDemande: String, Codable {
    case attente = "En attente", validee = "Validée", refusee = "Refusée"
}

struct DemandeMintza: Codable, Identifiable {
    var id = UUID()
    var commerce: CommerceMintza
    var auteur: UUID
    var miseAJour: Bool
    var date = Date()
    var statut: StatutDemande = .attente
    var motif = ""
}

struct EtatMintza: Codable {
    var profils: [ProfilMintza] = []
    var session: UUID?
    var commerces = CommerceMintza.exemples
    var demandes: [DemandeMintza] = []
}

struct MotMintza: Identifiable {
    var id: String { basque }
    let basque: String
    let francais: String
}

struct QuestionMintza {
    let enonce: String
    let choix: [String]
    let reponse: Int
    let explication: String
}

struct LeconMintza: Identifiable {
    let id: String
    let titre: String
    let icone: String
    let description: String
    let mots: [MotMintza]
    let questions: [QuestionMintza]

    static let toutes: [LeconMintza] = [
        LeconMintza(id: "salutations", titre: "Les salutations", icone: "hand.wave.fill", description: "Les premiers mots pour ouvrir la conversation.", mots: [
            MotMintza(basque: "Kaixo", francais: "Bonjour"), MotMintza(basque: "Agur", francais: "Au revoir"), MotMintza(basque: "Eskerrik asko", francais: "Merci"), MotMintza(basque: "Mesedez", francais: "S’il vous plaît"), MotMintza(basque: "Egun on", francais: "Bonjour (le matin)")
        ], questions: [
            QuestionMintza(enonce: "Comment saluer quelqu’un ?", choix: ["Agur", "Kaixo", "Ez"], reponse: 1, explication: "Kaixo signifie bonjour."),
            QuestionMintza(enonce: "Que signifie « Eskerrik asko » ?", choix: ["Merci", "Au revoir", "Bonjour"], reponse: 0, explication: "Eskerrik asko permet de remercier."),
            QuestionMintza(enonce: "Vous quittez un commerce. Que dites-vous ?", choix: ["Bai", "Egun on", "Agur"], reponse: 2, explication: "Agur signifie au revoir."),
            QuestionMintza(enonce: "Comment dire « S’il vous plaît » ?", choix: ["Mesedez", "Agur", "Kaixo"], reponse: 0, explication: "Mesedez accompagne une demande polie."),
            QuestionMintza(enonce: "Quelle salutation utilise-t-on le matin ?", choix: ["Gabon", "Egun on", "Arratsalde on"], reponse: 1, explication: "Egun on s’utilise le matin ; arratsalde on l’après-midi.")
        ]),
        LeconMintza(id: "presentation", titre: "Se présenter", icone: "person.fill", description: "Dites votre nom et faites connaissance.", mots: [
            MotMintza(basque: "Ni … naiz", francais: "Je suis …"), MotMintza(basque: "Zer moduz?", francais: "Comment ça va ?"), MotMintza(basque: "Ongi", francais: "Bien"), MotMintza(basque: "Bai", francais: "Oui"), MotMintza(basque: "Ez", francais: "Non")
        ], questions: [
            QuestionMintza(enonce: "Comment dire « Je suis Ane » ?", choix: ["Agur Ane", "Ni Ane naiz", "Ez Ane"], reponse: 1, explication: "Ni … naiz permet de se présenter."),
            QuestionMintza(enonce: "Que signifie « Zer moduz? » ?", choix: ["Comment ça va ?", "Combien ?", "Au revoir"], reponse: 0, explication: "Zer moduz? demande comment va votre interlocuteur."),
            QuestionMintza(enonce: "Comment répondre « Bien » ?", choix: ["Ez", "Mesedez", "Ongi"], reponse: 2, explication: "Ongi signifie bien."),
            QuestionMintza(enonce: "Que signifie « Bai » ?", choix: ["Non", "Oui", "Merci"], reponse: 1, explication: "Bai signifie oui."),
            QuestionMintza(enonce: "Comment dire « Non » ?", choix: ["Ez", "Bai", "Ongi"], reponse: 0, explication: "Ez signifie non.")
        ]),
        LeconMintza(id: "cafe", titre: "Au café", icone: "cup.and.saucer.fill", description: "Préparez votre première commande en euskara.", mots: [
            MotMintza(basque: "Kafe bat, mesedez", francais: "Un café, s’il vous plaît"), MotMintza(basque: "Ura", francais: "L’eau"), MotMintza(basque: "Esnea", francais: "Le lait"), MotMintza(basque: "Zenbat da?", francais: "Combien ça coûte ?"), MotMintza(basque: "Kontua, mesedez", francais: "L’addition, s’il vous plaît")
        ], questions: [
            QuestionMintza(enonce: "Comment commander un café ?", choix: ["Agur", "Kafe bat, mesedez", "Zer moduz?"], reponse: 1, explication: "Kafe bat, mesedez : un café, s’il vous plaît."),
            QuestionMintza(enonce: "Que signifie « Ura » ?", choix: ["Le lait", "Le café", "L’eau"], reponse: 2, explication: "Ura signifie l’eau."),
            QuestionMintza(enonce: "Comment demander le prix ?", choix: ["Zenbat da?", "Egun on", "Ni Ane naiz"], reponse: 0, explication: "Zenbat da? signifie combien ça coûte ?"),
            QuestionMintza(enonce: "Que signifie « Esnea » ?", choix: ["L’eau", "Le lait", "Le pain"], reponse: 1, explication: "Esnea signifie le lait."),
            QuestionMintza(enonce: "Comment demander l’addition ?", choix: ["Ongi", "Kaixo", "Kontua, mesedez"], reponse: 2, explication: "Kontua, mesedez : l’addition, s’il vous plaît.")
        ])
    ]
}
