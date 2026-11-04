import SwiftUI
import GoogleSignInSwift

private struct ChampAuthentification<Contenu: View>: View {
    let icone: String
    @ViewBuilder var contenu: () -> Contenu
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icone).foregroundStyle(Color.vertMintza).frame(width: 20).accessibilityHidden(true)
            contenu().frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 15).padding(.vertical, 12).frame(minHeight: 50)
        .background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.traitMintza, lineWidth: 1))
    }
}

private struct TitreAuthentification: View {
    let titre: LocalizedStringKey
    let sousTitre: LocalizedStringKey
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titre).font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Color.encreMintza)
            Text(sousTitre).font(.subheadline).foregroundStyle(.secondary)
        }.fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VueConnexion: View {
    var racine = false
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.colorScheme) private var apparence
    @StateObject private var connexionExterne = ConnexionExterne()
    @State private var connexionEnCours = false
    @State private var adresseEmail = ""
    @State private var motDePasse = ""
    @State private var erreur: String?
    @State private var demonstrationOuverte = false
    @FocusState private var champActif: Champ?
    private enum Champ { case email, motDePasse }

    var body: some View {
        Group {
            if magasin.profil != nil { VueProfil(racine: racine) }
            else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VueEnTete()
                        TitreAuthentification(titre: "Votre espace Mintza", sousTitre: "Chaque échange vous fait avancer.")
                        boutonGoogle
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.traitMintza).frame(height: 1)
                            Text("ou avec votre adresse e-mail").font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.center).layoutPriority(1)
                            Rectangle().fill(Color.traitMintza).frame(height: 1)
                        }.accessibilityElement(children: .combine)
                        VStack(spacing: 10) {
                            ChampAuthentification(icone: "envelope") {
                                TextField("Adresse e-mail", text: $adresseEmail)
                                    .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                                    .textContentType(.username).submitLabel(.next).focused($champActif, equals: .email)
                                    .accessibilityLabel("Adresse e-mail")
                            }
                            ChampAuthentification(icone: "lock") {
                                SecureField("Mot de passe", text: $motDePasse).textContentType(.password)
                                    .submitLabel(.go).focused($champActif, equals: .motDePasse).accessibilityLabel("Mot de passe")
                            }
                        }.onSubmit {
                            if champActif == .email { champActif = .motDePasse }
                            else { connecter() }
                        }
                        Button(action: connecter) { Text("Se connecter").frame(maxWidth: .infinity) }
                            .buttonStyle(StyleBoutonCapsulePrincipal()).disabled(!formulaireValide)
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                lienInscription
                                Spacer(minLength: 12)
                                lienRecuperation
                            }
                            VStack(spacing: 0) { lienInscription; lienRecuperation }.frame(maxWidth: .infinity)
                        }
                        DisclosureGroup(isExpanded: $demonstrationOuverte) {
                            VStack(spacing: 0) {
                                ForEach(RoleMintza.allCases) { role in
                                    Button {
                                        champActif = nil
                                        do { try magasin.ouvrirDemo(role) } catch { erreur = error.localizedDescription }
                                    } label: {
                                        HStack {
                                            Label(LocalizedStringKey(role.rawValue), systemImage: role == .administrateur ? "checkmark.shield" : role == .commercant ? "storefront" : "graduationcap")
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.caption)
                                        }.font(.subheadline).frame(minHeight: 44).contentShape(Rectangle())
                                    }.buttonStyle(.plain)
                                }
                            }.padding(.top, 6)
                        } label: {
                            Text("Explorer la démonstration").font(.subheadline.weight(.medium)).frame(minHeight: 44)
                        }.tint(.vertMintza)
                        Text("La progression est enregistrée sur cet appareil.").font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 22).padding(.vertical, 16)
                    .frame(maxWidth: 480).frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively).background(Color.fondMintza)
                .navigationTitle("Connexion").navigationBarTitleDisplayMode(.inline)
                .toolbar(racine ? .hidden : .visible, for: .navigationBar)
            }
        }.erreurMintza($erreur).disabled(connexionEnCours)
    }

    private var formulaireValide: Bool {
        !adresseEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !motDePasse.isEmpty
    }
    private var lienInscription: some View {
        NavigationLink(destination: VueInscription()) {
            Text("Créer mon compte").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
        }
    }
    private var lienRecuperation: some View {
        NavigationLink(destination: VueRecuperationCompte()) {
            Text("Mot de passe oublié ?").font(.caption).foregroundStyle(.secondary).frame(minHeight: 44)
        }
    }
    private var boutonGoogle: some View {
        Button(action: connecterAvecGoogle) {
            HStack(spacing: 12) {
                GoogleSignInButton(scheme: apparence == .dark ? .dark : .light, style: .icon) { }
                    .frame(width: 36, height: 36).clipShape(Circle())
                    .allowsHitTesting(false).accessibilityHidden(true)
                Text("Continuer avec Google").font(.body.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
                if connexionEnCours { ProgressView().tint(.vertMintza).accessibilityLabel("Connexion en cours…") }
                else { Image(systemName: "arrow.right").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true) }
            }
            .padding(.horizontal, 16).padding(.vertical, 10).frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.surfaceMintza, in: Capsule())
            .overlay(Capsule().stroke(Color.vertMintza.opacity(0.22), lineWidth: 1))
            .shadow(color: Color.black.opacity(apparence == .dark ? 0 : 0.04), radius: 7, x: 0, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain).disabled(connexionEnCours).accessibilityIdentifier("connexion-google")
    }
    private func connecter() {
        guard formulaireValide else { return }
        champActif = nil
        do { try magasin.connecter(email: adresseEmail, motDePasse: motDePasse); motDePasse = "" }
        catch { erreur = error.localizedDescription }
    }
    private func connecterAvecGoogle() {
        guard !connexionEnCours else { return }
        champActif = nil
        connexionEnCours = true
        Task {
            defer { connexionEnCours = false }
            do {
                let resultat = try await connexionExterne.connecterGoogle()
                try magasin.ouvrirSessionDistante(resultat.session, informationsGoogle: resultat.profil)
                motDePasse = ""
            } catch {
                if !ConnexionExterne.estAnnulation(error) { erreur = error.localizedDescription }
            }
        }
    }
}

struct VueInscription: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var tailleTexte
    @State private var prenom = ""
    @State private var nom = ""
    @State private var adresseEmail = ""
    @State private var motDePasse = ""
    @State private var confirmationMotDePasse = ""
    @State private var role: RoleMintza = .apprenant
    @State private var erreur: String?
    @FocusState private var champActif: Champ?
    private enum Champ: CaseIterable { case prenom, nom, email, motDePasse, confirmation }
    private var formulaireValide: Bool {
        !prenom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && MagasinMintza.emailValide(adresseEmail.trimmingCharacters(in: .whitespacesAndNewlines))
            && motDePasse.count >= 8 && confirmationMotDePasse == motDePasse
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VueEnTete()
                TitreAuthentification(titre: "Créer mon compte", sousTitre: "Chaque échange vous fait avancer.")
                VStack(spacing: 10) {
                    let disposition = tailleTexte.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
                    disposition {
                        ChampAuthentification(icone: "person") {
                            TextField("Prénom", text: $prenom).textContentType(.givenName).submitLabel(.next)
                                .focused($champActif, equals: .prenom).accessibilityLabel("Prénom")
                        }
                        ChampAuthentification(icone: "person") {
                            TextField("Nom", text: $nom).textContentType(.familyName).submitLabel(.next)
                                .focused($champActif, equals: .nom).accessibilityLabel("Nom")
                        }
                    }
                    ChampAuthentification(icone: "envelope") {
                        TextField("Adresse e-mail", text: $adresseEmail).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().textContentType(.username)
                            .submitLabel(.next).focused($champActif, equals: .email).accessibilityLabel("Adresse e-mail")
                    }
                    ChampAuthentification(icone: "lock") {
                        SecureField("Mot de passe", text: $motDePasse).textContentType(.newPassword)
                            .submitLabel(.next).focused($champActif, equals: .motDePasse).accessibilityLabel("Mot de passe")
                    }
                    ChampAuthentification(icone: "lock.badge.checkmark") {
                        SecureField("Confirmer le mot de passe", text: $confirmationMotDePasse).textContentType(.newPassword)
                            .submitLabel(.done).focused($champActif, equals: .confirmation).accessibilityLabel("Confirmer le mot de passe")
                    }
                }
                .onSubmit {
                    guard let champActif, let index = Champ.allCases.firstIndex(of: champActif) else { return }
                    if index + 1 < Champ.allCases.count { self.champActif = Champ.allCases[index + 1] }
                    else if formulaireValide { inscrire() }
                }
                if !confirmationMotDePasse.isEmpty && confirmationMotDePasse != motDePasse {
                    Text("Les mots de passe ne correspondent pas.").font(.caption).foregroundStyle(Color.rougeMintza)
                } else {
                    Text("8 caractères minimum.").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Je suis").font(.subheadline.weight(.medium))
                    Picker("Je suis", selection: $role) {
                        Text("Apprenant").tag(RoleMintza.apprenant)
                        Text("Commerçant").tag(RoleMintza.commercant)
                    }.pickerStyle(.segmented)
                }
                Button(action: inscrire) { Text("Créer mon compte").frame(maxWidth: .infinity) }
                    .buttonStyle(StyleBoutonCapsulePrincipal()).disabled(!formulaireValide)
                Text("Ce compte est local au prototype. Il n’est pas synchronisé avec un serveur.")
                    .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 22).padding(.vertical, 12).frame(maxWidth: 480).frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively).background(Color.fondMintza)
        .toolbar(.visible, for: .navigationBar).navigationTitle("S’inscrire").navigationBarTitleDisplayMode(.inline)
        .erreurMintza($erreur)
    }
    private func inscrire() {
        guard formulaireValide else { return }
        champActif = nil
        do {
            try magasin.inscrire(prenom: prenom, nom: nom, email: adresseEmail, motDePasse: motDePasse, role: role)
            dismiss()
        } catch { erreur = error.localizedDescription }
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
