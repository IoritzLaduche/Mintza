import SwiftUI

struct VueConnexion: View {
    var racine = false
    @EnvironmentObject private var magasin: MagasinMintza
    @State private var adresseEmail = ""
    @State private var motDePasse = ""
    @State private var erreur: String?
    var body: some View {
        Group {
            if magasin.profil != nil { VueProfil(racine: racine) }
            else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VueEnTete()
                        TitreMintza(titre: "Votre espace Mintza", sousTitre: "Chaque échange vous fait avancer.")
                        IllustrationMintza(nom: "MintzaAccueil", hauteur: 150).clipShape(RoundedRectangle(cornerRadius: 20))
                        ChampMintza(titre: "Adresse e-mail") {
                            TextField("vous@exemple.fr", text: $adresseEmail).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().textContentType(.username)
                        }
                        ChampMintza(titre: "Mot de passe") { SecureField("Mot de passe", text: $motDePasse).textContentType(.password) }
                        Button {
                            do { try magasin.connecter(email: adresseEmail, motDePasse: motDePasse); motDePasse = "" }
                            catch { erreur = error.localizedDescription }
                        } label: { Text("Se connecter").frame(maxWidth: .infinity) }
                            .buttonStyle(StyleBoutonCapsulePrincipal()).disabled(adresseEmail.isEmpty || motDePasse.isEmpty)
                        HStack {
                            NavigationLink("S’inscrire", destination: VueInscription())
                            Spacer()
                            NavigationLink("Mot de passe oublié ?", destination: VueRecuperationCompte()).font(.caption)
                        }.font(.subheadline.weight(.medium))
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Explorer la démonstration").font(.headline)
                            ForEach(RoleMintza.allCases) { role in
                                Button {
                                    do { try magasin.ouvrirDemo(role) } catch { erreur = error.localizedDescription }
                                } label: {
                                    HStack {
                                        Label(role.rawValue, systemImage: role == .administrateur ? "checkmark.shield" : role == .commercant ? "storefront" : "graduationcap")
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption)
                                    }.font(.subheadline).frame(minHeight: 44)
                                }
                            }
                        }.carteMintza()
                        Text("Prototype local : comptes et progression restent sur cet appareil.").font(.caption).foregroundStyle(.secondary)
                    }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
                }.scrollDismissesKeyboard(.interactively).background(Color.fondMintza)
                    .navigationTitle("Connexion").navigationBarTitleDisplayMode(.inline)
                    .toolbar(racine ? .hidden : .visible, for: .navigationBar)
            }
        }.erreurMintza($erreur)
    }
}

struct VueInscription: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.dismiss) private var dismiss
    @State private var prenom = ""
    @State private var nom = ""
    @State private var adresseEmail = ""
    @State private var motDePasse = ""
    @State private var confirmationMotDePasse = ""
    @State private var role: RoleMintza = .apprenant
    @State private var erreur: String?

    var body: some View {
        Form {
            Section("Informations personnelles") {
                TextField("Prénom", text: $prenom).textContentType(.givenName)
                TextField("Nom", text: $nom).textContentType(.familyName)
                Picker("Je suis", selection: $role) {
                    Text("Apprenant").tag(RoleMintza.apprenant)
                    Text("Commerçant").tag(RoleMintza.commercant)
                }
            }
            Section {
                TextField("Adresse e-mail", text: $adresseEmail).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().textContentType(.username)
                SecureField("Mot de passe", text: $motDePasse).textContentType(.newPassword)
                SecureField("Confirmer le mot de passe", text: $confirmationMotDePasse).textContentType(.newPassword)
            } header: { Text("Identifiants") } footer: { Text("8 caractères minimum. Les identifiants sont enregistrés dans le trousseau de cet appareil.") }
            Section {
                Button("Créer mon compte") {
                    guard motDePasse == confirmationMotDePasse else { erreur = "Les mots de passe ne correspondent pas."; return }
                    do {
                        try magasin.inscrire(prenom: prenom, nom: nom, email: adresseEmail, motDePasse: motDePasse, role: role)
                        dismiss()
                    } catch { erreur = error.localizedDescription }
                }
            } footer: { Text("Ce compte est local au prototype. Il n’est pas synchronisé avec un serveur.") }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("S’inscrire").navigationBarTitleDisplayMode(.inline).erreurMintza($erreur)
    }
}

struct VueRecuperationCompte: View {
    var body: some View {
        Form {
            Section {
                Label("Compte local", systemImage: "lock.shield").font(.headline)
                Text("Le prototype ne dispose pas de serveur d’authentification. La récupération par e-mail n’est donc pas encore disponible.")
                Text("Si vous avez oublié votre mot de passe, vous pouvez explorer les profils de démonstration ou créer un autre compte local. Votre ancien compte et sa progression restent conservés.")
                NavigationLink("Créer un autre compte", destination: VueInscription())
            }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("Aide à la connexion").navigationBarTitleDisplayMode(.inline)
    }
}
