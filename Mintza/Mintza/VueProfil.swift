import SwiftUI

struct VueProfil: View {
    var racine = false
    @EnvironmentObject private var magasin: MagasinMintza
    @State private var erreur: String?
    @State private var deconnexion = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VueEnTete()
                TitreMintza(titre: "Ma progression")
                if let profil = magasin.profil {
                    HStack(spacing: 16) {
                        Text(String(profil.prenom.prefix(1) + profil.nom.prefix(1)).uppercased())
                            .font(.title2.bold()).frame(width: 64, height: 64).background(Color.vertDouxMintza, in: Circle())
                        VStack(alignment: .leading, spacing: 6) {
                            Text(profil.prenom).font(.headline)
                            Text(profil.demonstration ? "Profil de démonstration" : "Apprendre aujourd’hui, profiter demain.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    TableauProgressionMintza()
                    VStack(spacing: 0) {
                        NavigationLink { VueModifierProfil(profil: profil) } label: { ligne("Modifier mon profil", icone: "person") }
                        Divider()
                        NavigationLink { VueFavoris() } label: { ligne("Mes favoris", icone: "heart") }
                        if profil.role == .commercant || magasin.estAdmin {
                            Divider()
                            NavigationLink { VueEspaceCommercant() } label: { ligne("Espace commerçant", icone: "storefront") }
                        }
                        if magasin.estAdmin {
                            Divider()
                            NavigationLink { VueAdministration() } label: { ligne("Administration", icone: "checkmark.shield") }
                        }
                        Divider()
                        NavigationLink { VueParametres() } label: { ligne("Paramètres", icone: "gearshape") }
                    }.buttonStyle(.plain).padding(.horizontal, 16).background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 20))
                    Button("Se déconnecter", role: .destructive) { deconnexion = true }.frame(maxWidth: .infinity).padding(.vertical, 8)
                }
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Color.fondMintza).toolbar(racine ? .hidden : .visible, for: .navigationBar).erreurMintza($erreur)
            .confirmationDialog("Se déconnecter ?", isPresented: $deconnexion, titleVisibility: .visible) {
                Button("Se déconnecter", role: .destructive) { do { try magasin.deconnecter() } catch { erreur = error.localizedDescription } }
            }
    }
    private func ligne(_ titre: String, icone: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icone).frame(width: 24).foregroundStyle(.secondary)
            Text(titre).font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 16).contentShape(Rectangle())
    }
}

struct TableauProgressionMintza: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @EnvironmentObject private var catalogue: CatalogueDistant
    @State private var erreur: String?
    private var jours: Int { magasin.profil?.activites.filter { $0.value > 0 }.count ?? 0 }
    private var semaine: [Date] {
        let calendrier = Calendar.current
        let debut = calendrier.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).compactMap { calendrier.date(byAdding: .day, value: $0, to: debut) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                StatistiqueMintza(valeur: "\(magasin.xp)", titre: "XP", icone: "star.fill", couleur: .orange)
                StatistiqueMintza(valeur: "\(magasin.nombreLeconsTerminees)", titre: "Leçons", icone: "book.fill")
                StatistiqueMintza(valeur: "\(jours)", titre: "Jours actifs", icone: "flame.fill", couleur: .orange)
            }
            VStack(alignment: .leading, spacing: 14) {
                Text("Activité cette semaine").font(.subheadline.bold())
                HStack {
                    ForEach(semaine, id: \.self) { jour in
                        let actif = (magasin.profil?.activites[MagasinMintza.cleJour(jour)] ?? 0) > 0
                        VStack(spacing: 10) {
                            Text(jour.formatted(.dateTime.weekday(.narrow))).font(.caption).foregroundStyle(.secondary)
                            Image(systemName: actif ? "checkmark.circle.fill" : "circle").foregroundStyle(actif ? Color.vertMintza : Color.traitMintza)
                        }.frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(jour.formatted(date: .complete, time: .omitted)) : \(actif ? "leçon terminée" : "aucune leçon")")
                    }
                }
            }.carteMintza()
            VStack(alignment: .leading, spacing: 14) {
                Text("Mes réussites").font(.subheadline.bold())
                HStack(alignment: .top, spacing: 12) {
                    badge("Premiers mots", detail: "Votre premier point en euskara.", icone: "bubble.left.fill", couleur: .rougeMintza, obtenu: magasin.xp > 0)
                    badge("Sans faute", detail: "Une leçon réussie sans erreur !", icone: "star.fill", couleur: .vertMintza, obtenu: magasin.sansFaute)
                }
            }.carteMintza()
            if let profil = magasin.profil {
                VStack(spacing: 14) {
                    HStack {
                        Label("Mon objectif", systemImage: "target").font(.subheadline.bold())
                        Spacer()
                        Text("\(profil.objectif) leçon(s) par jour").font(.caption)
                    }
                    HStack(spacing: 24) {
                        Button { changerObjectif(profil.objectif - 1, profil: profil) } label: { Image(systemName: "minus").frame(width: 44, height: 44).background(Color.fondMintza, in: Circle()) }.disabled(profil.objectif <= 1).accessibilityLabel("Diminuer l’objectif")
                        Text("\(profil.objectif)").font(.title3.bold())
                        Button { changerObjectif(profil.objectif + 1, profil: profil) } label: { Image(systemName: "plus").frame(width: 44, height: 44).background(Color.fondMintza, in: Circle()) }.disabled(profil.objectif >= 5).accessibilityLabel("Augmenter l’objectif")
                    }.buttonStyle(.plain)
                }.carteMintza()
            }
            DisclosureGroup("Mes meilleurs scores") {
                VStack(spacing: 14) {
                    ForEach(catalogue.lecons.filter { magasin.profil?.resultatsDistants?[String($0.id)] != nil }) { lecon in
                        NavigationLink { VueLeconDistante(lecon: lecon) } label: {
                            if let resultat = magasin.profil?.resultatsDistants?[String(lecon.id)] {
                                HStack { Text(lecon.titreLecon); Spacer(); Text("\(resultat.bonnesReponses)/\(resultat.total)") }.font(.subheadline)
                            }
                        }
                    }
                    ForEach(LeconMintza.toutes) { lecon in
                        NavigationLink { VueLecon(lecon: lecon) } label: {
                            HStack { Text(lecon.titre); Spacer(); Text(magasin.profil?.scores[lecon.id].map { "\($0)/5" } ?? "—") }.font(.subheadline)
                        }
                    }
                }.padding(.top, 14)
            }.font(.subheadline).carteMintza()
        }.erreurMintza($erreur)
    }
    private func badge(_ titre: String, detail: String, icone: String, couleur: Color, obtenu: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: obtenu ? icone : "lock.fill").font(.title2).foregroundStyle(obtenu ? .white : .secondary)
                .frame(width: 56, height: 56).background(obtenu ? couleur : Color.traitMintza, in: Circle())
                .overlay(Circle().stroke(couleur.opacity(obtenu ? 0.25 : 0), lineWidth: 5))
            Text(titre).font(.caption.bold())
            Text(obtenu ? detail : "À débloquer").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 10)
    }
    private func changerObjectif(_ valeur: Int, profil: ProfilMintza) {
        do { try magasin.modifierProfil(prenom: profil.prenom, nom: profil.nom, objectif: valeur) }
        catch { erreur = error.localizedDescription }
    }
}

struct VueModifierProfil: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.dismiss) private var dismiss
    @State private var prenom: String
    @State private var nom: String
    @State private var objectif: Int
    @State private var erreur: String?

    init(profil: ProfilMintza) {
        _prenom = State(initialValue: profil.prenom)
        _nom = State(initialValue: profil.nom)
        _objectif = State(initialValue: profil.objectif)
    }
    var body: some View {
        Form {
            Section("Informations personnelles") {
                TextField("Prénom", text: $prenom)
                TextField("Nom", text: $nom)
            }
            Section("Mon rythme") { Stepper("\(objectif) leçon(s) par jour", value: $objectif, in: 1...5) }
            Button("Enregistrer") {
                do { try magasin.modifierProfil(prenom: prenom, nom: nom, objectif: objectif); dismiss() }
                catch { erreur = error.localizedDescription }
            }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("Modifier mon profil").navigationBarTitleDisplayMode(.inline).erreurMintza($erreur)
    }
}

struct VueProgression: View {
    var body: some View {
        ScrollView { TableauProgressionMintza().padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity) }
            .background(Color.fondMintza).navigationTitle("Ma progression").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}

struct VueFavoris: View {
    @EnvironmentObject private var magasin: MagasinMintza
    private var favoris: [CommerceMintza] { magasin.etat.commerces.filter { magasin.profil?.favoris.contains($0.id) == true } }
    var body: some View {
        Group {
            if favoris.isEmpty {
                ContentUnavailableView("Aucun favori", systemImage: "heart", description: Text("Ouvrez une fiche depuis la carte et touchez le cœur pour la retrouver ici."))
            } else {
                List(favoris) { commerce in
                    NavigationLink { VueFicheCommerce(commerceID: commerce.id) } label: { LigneCommerce(commerce: commerce) }
                }
            }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("Mes favoris")
    }
}

struct VueParametres: View {
    @AppStorage("langueAppli") private var langue = "fr"
    var body: some View {
        Form {
            Section("Langue de l’interface") {
                Picker("Langue", selection: $langue) { Text("Français").tag("fr"); Text("Euskara").tag("eu") }
                Text("La traduction basque de l’interface est partielle dans ce prototype. Les leçons proposent le vocabulaire dans les deux langues.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("À propos de Mintza") {
                Text("Apprendre, pratiquer, fédérer.").font(.headline)
                Text("Un projet étudiant ISA NUM pour rapprocher l’apprentissage de l’euskara des échanges du quotidien dans le Pays Basque.")
                LabeledContent("Version", value: "Prototype 1.0")
            }
            Section("Données et confidentialité") {
                Text("Comptes, scores, favoris et demandes sont enregistrés sur cet appareil. Les mots de passe sont conservés dans le trousseau iOS. Aucun serveur de comptes n’est connecté.")
                Text("Les quatre commerces initiaux sont fictifs et servent à la démonstration. Le fond de carte et les itinéraires utilisent les services Apple et peuvent nécessiter Internet.")
                Text("L’accès à votre position est facultatif et demandé uniquement lorsque vous touchez le bouton de localisation sur la carte.")
            }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("Paramètres").navigationBarTitleDisplayMode(.inline)
    }
}
