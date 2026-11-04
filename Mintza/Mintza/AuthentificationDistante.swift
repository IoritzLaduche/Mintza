import Foundation
import Combine
import Security
import GoogleSignIn
import UIKit

struct ProfilServeurMintza: Codable {
    let idUtilisateur: Int
    let pseudo: String
    let email: String?
    let roleUtilisateur: String
}

struct SessionServeurMintza: Codable {
    let jeton: String
    let expiration: TimeInterval
    var profil: ProfilServeurMintza
    var adresseAPI: String?
}

struct InformationsProfilGoogle {
    let prenom: String?
    let nom: String?

    init(prenom: String?, nom: String?) {
        func nettoyer(_ valeur: String?) -> String? {
            guard let valeur = valeur?.trimmingCharacters(in: .whitespacesAndNewlines), !valeur.isEmpty else { return nil }
            return String(valeur.prefix(100))
        }
        self.prenom = nettoyer(prenom)
        self.nom = nettoyer(nom)
    }
}

private struct DefiConnexion: Decodable {
    let identifiant: String
    let nonce: String
}

struct ErreurConnexionDistante: LocalizedError {
    let message: String
    var statut: Int? = nil
    var errorDescription: String? { message }
}

enum ConfigurationConnexion {
    static func valeur(_ cle: String) throws -> String {
        guard let valeur = Bundle.main.object(forInfoDictionaryKey: cle) as? String,
              !valeur.isEmpty, !valeur.contains("A_REMPLACER"), !valeur.contains("$(") else {
            throw ErreurConnexionDistante(message: "Ce mode de connexion n’est pas encore configuré.")
        }
        return valeur
    }

    static func adresse() throws -> URL {
        let valeur = try valeur("MintzaAuthURL")
        guard let url = URL(string: valeur), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else {
            throw ErreurConnexionDistante(message: "La connexion nécessite une adresse de serveur HTTPS valide.")
        }
        return url
    }
}

// Aucune preuve d'identité ou session n'est envoyée à une autre URL après redirection.
private final class RefusRedirectionConnexion: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                               willPerformHTTPRedirection response: HTTPURLResponse,
                               newRequest request: URLRequest,
                               completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

private struct MessageConnexionServeur: Decodable { let erreur: String }

struct APIConnexion {
    private static let reseau: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpShouldSetCookies = false
        return URLSession(configuration: configuration, delegate: RefusRedirectionConnexion(), delegateQueue: nil)
    }()

    func demander<T: Decodable>(_ route: String, corps: [String: String]? = nil, jeton: String? = nil) async throws -> T {
        let adresse = try ConfigurationConnexion.adresse()
        var composants = URLComponents(url: adresse, resolvingAgainstBaseURL: false)!
        composants.queryItems = [URLQueryItem(name: "route", value: route)]
        var requete = URLRequest(url: composants.url!)
        requete.httpMethod = corps == nil ? "GET" : "POST"
        requete.setValue("application/json", forHTTPHeaderField: "Accept")
        if let corps {
            requete.setValue("application/json", forHTTPHeaderField: "Content-Type")
            requete.httpBody = try JSONEncoder().encode(corps)
        }
        if let jeton { requete.setValue("Bearer \(jeton)", forHTTPHeaderField: "Authorization") }
        let (donnees, reponse) = try await Self.reseau.data(for: requete)
        guard let http = reponse as? HTTPURLResponse else {
            throw ErreurConnexionDistante(message: "Le serveur n’a pas répondu correctement.")
        }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(MessageConnexionServeur.self, from: donnees))?.erreur
            throw ErreurConnexionDistante(message: message ?? "Connexion impossible. Réessayez.", statut: http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: donnees)
    }

    func verifier(_ session: SessionServeurMintza) async throws -> ProfilServeurMintza {
        guard session.adresseAPI == (try ConfigurationConnexion.adresse()).absoluteString else {
            throw ErreurConnexionDistante(message: "Le serveur a changé. Reconnectez-vous.", statut: 401)
        }
        return try await demander("auth-session", jeton: session.jeton)
    }

    func deconnecter(_ session: SessionServeurMintza) async throws {
        guard session.adresseAPI == (try ConfigurationConnexion.adresse()).absoluteString else { return }
        let _: [String: String] = try await demander("auth-deconnexion", corps: [:], jeton: session.jeton)
    }
}

enum CoffreSessionMintza {
    private static var requete: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "mintza.session.serveur",
         kSecAttrAccount as String: "session-active"]
    }

    static func lire() throws -> SessionServeurMintza? {
        var recherche = requete
        recherche[kSecReturnData as String] = true
        recherche[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultat: CFTypeRef?
        let statut = SecItemCopyMatching(recherche as CFDictionary, &resultat)
        if statut == errSecItemNotFound { return nil }
        guard statut == errSecSuccess, let donnees = resultat as? Data else {
            throw ErreurMintza("Impossible de lire la session. Déverrouillez l’iPhone et réessayez.")
        }
        return try JSONDecoder().decode(SessionServeurMintza.self, from: donnees)
    }

    static func enregistrer(_ session: SessionServeurMintza) throws {
        let donnees = try JSONEncoder().encode(session)
        let attributs = [kSecValueData as String: donnees]
        var statut = SecItemUpdate(requete as CFDictionary, attributs as CFDictionary)
        if statut == errSecItemNotFound {
            var ajout = requete.merging(attributs) { _, nouveau in nouveau }
            ajout[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            statut = SecItemAdd(ajout as CFDictionary, nil)
        }
        guard statut == errSecSuccess else { throw ErreurMintza("Impossible de conserver la session sur cet appareil.") }
    }

    static func effacer() throws {
        let statut = SecItemDelete(requete as CFDictionary)
        guard statut == errSecSuccess || statut == errSecItemNotFound else {
            throw ErreurMintza("Impossible de fermer la session sur cet appareil.")
        }
    }
}

@MainActor
final class ConnexionExterne: ObservableObject {
    private let api = APIConnexion()

    private func presenter() throws -> UIViewController {
        guard let fenetre = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?.windows.first(where: \.isKeyWindow),
              var vue = fenetre.rootViewController else {
            throw ErreurMintza("Impossible d’ouvrir la connexion. Réessayez.")
        }
        while let presentee = vue.presentedViewController { vue = presentee }
        return vue
    }

    func connecterGoogle() async throws -> (session: SessionServeurMintza, profil: InformationsProfilGoogle?) {
        let client = try ConfigurationConnexion.valeur("GIDClientID")
        let serveur = try ConfigurationConnexion.valeur("GIDServerClientID")
        guard client.hasSuffix(".apps.googleusercontent.com"), serveur.hasSuffix(".apps.googleusercontent.com"),
              client != serveur, !client.contains(" "), !serveur.contains(" ") else {
            throw ErreurMintza("Les identifiants de connexion Google sont incomplets.")
        }
        let retour = client.split(separator: ".").reversed().joined(separator: ".")
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        guard types.contains(where: { ($0["CFBundleURLSchemes"] as? [String])?.contains(retour) == true }) else {
            throw ErreurMintza("Le retour de connexion Google n’est pas encore configuré.")
        }
        let defi: DefiConnexion = try await api.demander("auth-defi", corps: ["fournisseur": "google"])
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: client, serverClientID: serveur)
        let resultat = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter(), hint: nil, additionalScopes: nil, nonce: defi.nonce)
        guard let jeton = resultat.user.idToken?.tokenString else { throw ErreurMintza("Google n’a pas fourni de preuve de connexion.") }
        // La session est créée uniquement après vérification du jeton par le serveur.
        let session = try await terminer(fournisseur: "google", jeton: jeton, defi: defi)
        let profil = resultat.user.profile.map {
            InformationsProfilGoogle(prenom: $0.givenName ?? ($0.familyName == nil ? $0.name : nil), nom: $0.familyName)
        }
        return (session, profil)
    }

    private func terminer(fournisseur: String, jeton: String, defi: DefiConnexion) async throws -> SessionServeurMintza {
        var session: SessionServeurMintza = try await api.demander("auth-" + fournisseur, corps: ["jeton": jeton, "defi": defi.identifiant])
        session.adresseAPI = try ConfigurationConnexion.adresse().absoluteString
        return session
    }

    static func estAnnulation(_ erreur: Error) -> Bool {
        let erreur = erreur as NSError
        // Le SDK déclare kGIDSignInErrorCodeCanceled = -5.
        return (erreur.domain == kGIDSignInErrorDomain && erreur.code == -5)
            || (erreur.domain == NSURLErrorDomain && erreur.code == NSURLErrorCancelled)
    }
}
