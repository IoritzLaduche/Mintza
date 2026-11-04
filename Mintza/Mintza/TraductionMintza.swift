import SwiftUI

/// Traduction explicite pour les valeurs d'énumérations et messages calculés.
/// Les noms de personnes, adresses et réponses pédagogiques restent des données.
enum TraductionMintza {
    static func texte(_ valeur: String, langue: String? = nil) -> String {
        let code = langue ?? UserDefaults.standard.string(forKey: "langueAppli") ?? "fr"
        guard let chemin = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: chemin) else { return valeur }
        let exact = bundle.localizedString(forKey: valeur, value: valeur, table: "Localizable")
        if exact != valeur || code == "fr" { return exact }
        for prefixe in ["Impossible de vérifier la connexion.", "Les données locales ne peuvent pas être lues. Elles sont conservées sans modification."] {
            if valeur.hasPrefix(prefixe + " ") {
                return bundle.localizedString(forKey: prefixe, value: prefixe, table: "Localizable")
                    + " " + texte(String(valeur.dropFirst(prefixe.count + 1)), langue: code)
            }
        }
        for (motif, cle) in [
            (#"^Le serveur a répondu avec l’erreur (\d+)\.$"#, "Le serveur a répondu avec l’erreur %lld."),
            (#"^Le contenu de l’exercice (\d+) est incomplet\. Signalez-le à l’équipe Mintza\.$"#, "Le contenu de l’exercice %lld est incomplet. Signalez-le à l’équipe Mintza.")
        ] {
            if let regex = try? NSRegularExpression(pattern: motif),
               let resultat = regex.firstMatch(in: valeur, range: NSRange(valeur.startIndex..., in: valeur)),
               let plage = Range(resultat.range(at: 1), in: valeur), let nombre = Int64(valeur[plage]) {
                return String(format: bundle.localizedString(forKey: cle, value: cle, table: "Localizable"), nombre)
            }
        }
        return valeur
    }
}

struct MessageInterface: View {
    @Environment(\.locale) private var locale
    let message: String
    init(_ message: String) { self.message = message }
    var body: some View {
        Text(verbatim: TraductionMintza.texte(message, langue: locale.language.languageCode?.identifier ?? "fr"))
    }
}
