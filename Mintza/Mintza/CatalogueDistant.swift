import Foundation
import Combine

// Ce contrat reprend les noms renvoyés par l’API PHP.
struct LeconDistante: Decodable, Identifiable, Sendable {
    let idLecon: Int
    let titreLecon: String
    let niveauLecon: String
    let descriptionLecon: String?
    let ordreLecon: Int
    var id: Int { idLecon }
}

enum TypeExercice: String, Decodable, Sendable {
    case qcm, vrai_faux, phrase_trou, dialogue, association, ordre_mots, comprehension_ecrite
}

struct ElementExercice: Decodable, Identifiable, Sendable {
    let id: String
    let texte: String
}

struct PaireExercice: Decodable, Sendable {
    let gaucheId: String
    let droiteId: String
}

struct ContenuExercice: Decodable, Sendable {
    let choix: [ElementExercice]?
    let affirmation: String?
    let phrase: String?
    let situation: String?
    let replique: String?
    let gauche: [ElementExercice]?
    let droite: [ElementExercice]?
    let mots: [ElementExercice]?
    let texte: String?
}

struct CorrectionExercice: Decodable, Sendable {
    let choixId: String?
    let valeur: Bool?
    let paires: [PaireExercice]?
    let ordre: [String]?
}

struct ExerciceDistant: Decodable, Identifiable, Sendable {
    let idExo: Int
    let idLecon: Int
    let typeExo: TypeExercice
    let libelleExo: String
    let contenuExo: ContenuExercice
    let reponseExo: CorrectionExercice
    let explicationExo: String?
    let ordreExo: Int
    var id: Int { idExo }

    // Une réponse incomplète de l’API ne doit pas devenir un exercice impossible.
    func valider() throws {
        func uniques(_ elements: [ElementExercice]) -> Bool {
            Set(elements.map(\.id)).count == elements.count
                && elements.allSatisfy { !$0.id.isEmpty && !$0.texte.isEmpty }
        }
        let valide: Bool
        switch typeExo {
        case .qcm, .phrase_trou, .dialogue, .comprehension_ecrite:
            let choix = contenuExo.choix ?? []
            let base = choix.count == 3 && uniques(choix)
                && choix.contains { $0.id == reponseExo.choixId }
            switch typeExo {
            case .phrase_trou:
                valide = base && (contenuExo.phrase?.components(separatedBy: "___").count == 2)
            case .dialogue:
                valide = base && contenuExo.situation?.isEmpty == false && contenuExo.replique?.isEmpty == false
            case .comprehension_ecrite:
                valide = base && contenuExo.texte?.isEmpty == false
            default: valide = base
            }
        case .vrai_faux:
            valide = contenuExo.affirmation?.isEmpty == false && reponseExo.valeur != nil
        case .association:
            let gauche = contenuExo.gauche ?? [], droite = contenuExo.droite ?? []
            let paires = reponseExo.paires ?? []
            valide = gauche.count == 3 && droite.count == 3 && paires.count == 3
                && uniques(gauche) && uniques(droite)
                && Set(paires.map(\.gaucheId)) == Set(gauche.map(\.id))
                && Set(paires.map(\.droiteId)) == Set(droite.map(\.id))
        case .ordre_mots:
            let mots = contenuExo.mots ?? [], ordre = reponseExo.ordre ?? []
            valide = (3...8).contains(mots.count) && uniques(mots)
                && ordre.count == mots.count && Set(ordre) == Set(mots.map(\.id))
        }
        guard valide, idExo > 0, idLecon > 0, !libelleExo.isEmpty else {
            throw ErreurCatalogue(message: "Le contenu de l’exercice \(idExo) est incomplet. Signalez-le à l’équipe Mintza.")
        }
    }

    func estCorrect(choix: String?, valeur: Bool?, paires: [String: String], ordre: [String]) -> Bool {
        switch typeExo {
        case .qcm, .phrase_trou, .dialogue, .comprehension_ecrite:
            return choix != nil && choix == reponseExo.choixId
        case .vrai_faux:
            return valeur != nil && valeur == reponseExo.valeur
        case .association:
            let attendues = reponseExo.paires ?? []
            return paires.count == attendues.count && !attendues.isEmpty
                && attendues.allSatisfy { paires[$0.gaucheId] == $0.droiteId }
        case .ordre_mots:
            return !ordre.isEmpty && ordre == reponseExo.ordre
        }
    }

    var correctionLisible: String {
        switch typeExo {
        case .qcm, .phrase_trou, .dialogue, .comprehension_ecrite:
            return contenuExo.choix?.first { $0.id == reponseExo.choixId }?.texte ?? ""
        case .vrai_faux: return reponseExo.valeur == true ? "Vrai" : "Faux"
        case .association:
            return (contenuExo.gauche ?? []).map { element in
                let cible = reponseExo.paires?.first { $0.gaucheId == element.id }?.droiteId
                let texte = contenuExo.droite?.first { $0.id == cible }?.texte ?? ""
                return "\(element.texte) → \(texte)"
            }.joined(separator: "\n")
        case .ordre_mots:
            return (reponseExo.ordre ?? []).compactMap { identifiant in
                contenuExo.mots?.first { $0.id == identifiant }?.texte
            }.joined(separator: " ")
        }
    }
}

struct ResultatLeconDistante: Codable {
    let bonnesReponses: Int
    let total: Int
}

struct ErreurCatalogue: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private struct MessageServeur: Decodable { let erreur: String }

struct ServiceCatalogue {
    // Adresse de l’API uniquement : aucun identifiant MariaDB dans l’application.
    static let adresseVM = URL(string: "http://10.3.16.227/api/index.php")!
    let adresse: URL
    let session: URLSession

    init(adresse: URL = ServiceCatalogue.adresseVM, session: URLSession? = nil) {
        self.adresse = adresse
        if let session { self.session = session }
        else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 30
            self.session = URLSession(configuration: configuration)
        }
    }

    func lecons() async throws -> [LeconDistante] {
        let lecons: [LeconDistante] = try await lire(route: "lecons")
        guard Set(lecons.map(\.id)).count == lecons.count,
              lecons.allSatisfy({ $0.id > 0 && ["A1", "A2", "B1", "B2", "C1", "C2"].contains($0.niveauLecon) }) else {
            throw ErreurCatalogue(message: "La liste des leçons reçue est invalide.")
        }
        return lecons.sorted { ($0.ordreLecon, $0.id) < ($1.ordreLecon, $1.id) }
    }

    func exercices(idLecon: Int) async throws -> [ExerciceDistant] {
        let exercices: [ExerciceDistant] = try await lire(route: "exercices", parametres: [URLQueryItem(name: "idLecon", value: String(idLecon))])
        guard Set(exercices.map(\.id)).count == exercices.count,
              exercices.allSatisfy({ $0.idLecon == idLecon }) else {
            throw ErreurCatalogue(message: "Les exercices reçus ne correspondent pas à cette leçon.")
        }
        for exercice in exercices { try exercice.valider() }
        return exercices.sorted { ($0.ordreExo, $0.id) < ($1.ordreExo, $1.id) }
    }

    private func lire<T: Decodable>(route: String, parametres: [URLQueryItem] = []) async throws -> T {
        guard var composants = URLComponents(url: adresse, resolvingAgainstBaseURL: false) else {
            throw ErreurCatalogue(message: "L’adresse du serveur est invalide.")
        }
        composants.queryItems = [URLQueryItem(name: "route", value: route)] + parametres
        guard let url = composants.url else { throw ErreurCatalogue(message: "L’adresse du serveur est invalide.") }
        var requete = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        requete.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (donnees, reponse) = try await session.data(for: requete)
            try Task.checkCancellation()
            guard let http = reponse as? HTTPURLResponse else {
                throw ErreurCatalogue(message: "Le serveur n’a pas fourni de réponse HTTP.")
            }
            guard (200...299).contains(http.statusCode) else {
                let detail = try? JSONDecoder().decode(MessageServeur.self, from: donnees).erreur
                throw ErreurCatalogue(message: detail ?? "Le serveur a répondu avec l’erreur \(http.statusCode).")
            }
            return try JSONDecoder().decode(T.self, from: donnees)
        } catch let erreur as URLError {
            if erreur.code == .cancelled { throw CancellationError() }
            throw ErreurCatalogue(message: "Impossible de joindre Mintza. Vérifiez l’accès au Wi-Fi de la fac ou au VPN, ainsi que l’autorisation Réseau local dans les réglages de l’iPhone.")
        } catch is DecodingError {
            throw ErreurCatalogue(message: "Le format des données reçues ne correspond pas à celui de l’application.")
        }
    }
}

@MainActor
final class CatalogueDistant: ObservableObject {
    @Published private(set) var lecons: [LeconDistante] = []
    @Published private(set) var chargement = false
    @Published private(set) var erreur: String?
    private var dejaCharge = false
    let service = ServiceCatalogue()

    func charger(force: Bool = false) async {
        guard !chargement, force || !dejaCharge else { return }
        chargement = true
        erreur = nil
        defer { chargement = false }
        do {
            lecons = try await service.lecons()
            dejaCharge = true
        } catch is CancellationError { }
        catch { self.erreur = error.localizedDescription }
    }
}
