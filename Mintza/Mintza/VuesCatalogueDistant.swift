import SwiftUI

struct VueApprentissageDistant: View {
    var racine = false
    @EnvironmentObject private var catalogue: CatalogueDistant
    @EnvironmentObject private var magasin: MagasinMintza
    @State private var niveau = "A1"
    private var lecons: [LeconDistante] { catalogue.lecons.filter { $0.niveauLecon == niveau } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VueEnTete()
                TitreMintza(titre: "Apprendre", sousTitre: "Le basque, à votre rythme")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["A1", "A2", "B1", "B2", "C1", "C2"], id: \.self) { valeur in
                            Button { niveau = valeur } label: {
                                Text(valeur).font(.subheadline.weight(.medium)).frame(minWidth: 45, minHeight: 44)
                                    .background(niveau == valeur ? Color.vertMintza : Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 16))
                                    .foregroundStyle(niveau == valeur ? Color.white : Color.encreMintza)
                            }.buttonStyle(.plain).accessibilityAddTraits(niveau == valeur ? .isSelected : [])
                        }
                    }
                }
                if catalogue.chargement && catalogue.lecons.isEmpty {
                    ProgressView("Chargement des leçons…").frame(maxWidth: .infinity).padding(.vertical, 40)
                }
                if let erreur = catalogue.erreur {
                    VueErreurCatalogue(message: erreur) { Task { await catalogue.charger(force: true) } }
                }
                if !catalogue.chargement && catalogue.erreur == nil && lecons.isEmpty {
                    ContentUnavailableView("Aucune leçon pour ce niveau", systemImage: "books.vertical", description: Text("De nouvelles leçons seront ajoutées prochainement."))
                }
                ForEach(lecons) { lecon in
                    NavigationLink { VueLeconDistante(lecon: lecon) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "book.closed.fill").font(.title2).foregroundStyle(Color.vertMintza)
                                .frame(width: 60, height: 70).background(Color.vertDouxMintza, in: RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lecon.niveauLecon).font(.caption).foregroundStyle(.secondary)
                                Text(lecon.titreLecon).font(.headline).foregroundStyle(Color.encreMintza)
                                if let resultat = magasin.profil?.resultatsDistants?[String(lecon.id)] {
                                    Label("Terminé · \(resultat.bonnesReponses)/\(resultat.total)", systemImage: "checkmark.circle.fill")
                                        .font(.caption).foregroundStyle(Color.vertMintza)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }.padding(12).background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain)
                }
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Color.fondMintza).navigationTitle("Apprendre").navigationBarTitleDisplayMode(.inline)
            .toolbar(racine ? .hidden : .visible, for: .navigationBar)
            .task { await catalogue.charger() }
            .refreshable { await catalogue.charger(force: true) }
    }
}

struct VueErreurCatalogue: View {
    let message: String
    let reessayer: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connexion au catalogue", systemImage: "wifi.exclamationmark").font(.headline)
            Text(message).font(.subheadline)
            Button("Réessayer", action: reessayer).buttonStyle(.bordered)
        }.frame(maxWidth: .infinity, alignment: .leading).carteMintza()
    }
}

struct VueLeconDistante: View {
    let lecon: LeconDistante
    @EnvironmentObject private var catalogue: CatalogueDistant
    @State private var exercices: [ExerciceDistant] = []
    @State private var chargement = true
    @State private var erreur: String?
    @State private var quizOuvert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IllustrationMintza(nom: "MintzaVocabulaire", hauteur: 200).clipShape(RoundedRectangle(cornerRadius: 22))
                Text(lecon.niveauLecon).font(.headline).foregroundStyle(Color.vertMintza)
                Text(lecon.titreLecon).font(.title.bold())
                if let description = lecon.descriptionLecon { Text(description) }
                if chargement {
                    ProgressView("Chargement des exercices…")
                } else if let erreur {
                    VueErreurCatalogue(message: erreur) { Task { await charger() } }
                } else if exercices.isEmpty {
                    ContentUnavailableView("Cette leçon se prépare", systemImage: "books.vertical", description: Text("Elle ne contient pas encore d’exercice."))
                } else {
                    Label("\(exercices.count) exercices", systemImage: "list.bullet.rectangle").foregroundStyle(.secondary)
                    Button { quizOuvert = true } label: {
                        Label("Commencer", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(StyleBoutonCapsulePrincipal())
                }
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Color.fondMintza)
            .navigationTitle("Votre leçon").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .task { await charger() }
            .fullScreenCover(isPresented: $quizOuvert) {
                NavigationStack { VueExercicesDistants(lecon: lecon, exercices: exercices) }
                    .tint(.vertMintza).foregroundStyle(Color.encreMintza)
            }
    }

    private func charger() async {
        chargement = true
        erreur = nil
        defer { chargement = false }
        do { exercices = try await catalogue.service.exercices(idLecon: lecon.id) }
        catch is CancellationError { }
        catch { self.erreur = error.localizedDescription }
    }
}

struct VueExercicesDistants: View {
    let lecon: LeconDistante
    let exercices: [ExerciceDistant]
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.dismiss) private var fermer
    @State private var index = 0
    @State private var choix: String?
    @State private var valeur: Bool?
    @State private var paires: [String: String] = [:]
    @State private var gaucheActive: String?
    @State private var ordre: [String] = []
    @State private var corrige = false
    @State private var bonneReponse = false
    @State private var score = 0
    @State private var termine = false
    @State private var quitter = false
    @State private var sauvegarde = false
    @State private var erreurSauvegarde: String?
    private var exercice: ExerciceDistant? { exercices.indices.contains(index) ? exercices[index] : nil }

    private var reponseComplete: Bool {
        guard let exercice else { return false }
        switch exercice.typeExo {
        case .qcm, .phrase_trou, .dialogue, .comprehension_ecrite: return choix != nil
        case .vrai_faux: return valeur != nil
        case .association: return paires.count == exercice.contenuExo.gauche?.count
        case .ordre_mots: return ordre.count == exercice.contenuExo.mots?.count
        }
    }

    var body: some View {
        ScrollViewReader { defilement in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Color.clear.frame(height: 1).id("haut")
                    if termine { resultat }
                    else if let exercice {
                        Text("Exercice \(index + 1) sur \(exercices.count)").font(.subheadline)
                        ProgressView(value: Double(index + 1), total: Double(exercices.count)).tint(.vertMintza)
                        // Le texte fourni par l’API est toujours affiché comme texte littéral.
                        Text(exercice.libelleExo).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                        contenu(exercice)
                        if corrige {
                            VStack(alignment: .leading, spacing: 12) {
                                Label(bonneReponse ? "Bonne réponse !" : "À retenir", systemImage: bonneReponse ? "checkmark.circle.fill" : "lightbulb.fill").font(.headline)
                                if !bonneReponse { Text(exercice.correctionLisible).font(.body.weight(.semibold)) }
                                if let explication = exercice.explicationExo { Text(explication).font(.subheadline) }
                            }.frame(maxWidth: .infinity, alignment: .leading).carteMintza()
                                .accessibilityElement(children: .combine)
                        }
                    }
                }.padding(24).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }.background(Color.fondMintza)
                .onChange(of: index) { _, _ in defilement.scrollTo("haut", anchor: .top) }
                .onChange(of: termine) { _, _ in defilement.scrollTo("haut", anchor: .top) }
        }
        .safeAreaInset(edge: .bottom) {
            if !termine && exercice != nil {
                Button(action: avancer) {
                    Text(corrige ? (index + 1 == exercices.count ? "Voir mon résultat" : "Exercice suivant") : "Vérifier")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(StyleBoutonCapsulePrincipal()).disabled(!reponseComplete)
                    .padding(22).background(Color.fondMintza)
            }
        }
        .navigationTitle(lecon.niveauLecon).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { if termine { fermer() } else { quitter = true } } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }.accessibilityLabel("Quitter les exercices")
            }
        }
        .confirmationDialog("Quitter cette tentative ? Les réponses en cours ne seront pas enregistrées.", isPresented: $quitter, titleVisibility: .visible) {
            Button("Quitter", role: .destructive) { fermer() }
        }
    }

    @ViewBuilder
    private func contenu(_ exercice: ExerciceDistant) -> some View {
        switch exercice.typeExo {
        case .qcm:
            boutonsChoix(exercice.contenuExo.choix ?? [])
        case .phrase_trou:
            Text(exercice.contenuExo.phrase ?? "").font(.title3).carteMintza()
            boutonsChoix(exercice.contenuExo.choix ?? [])
        case .dialogue:
            Text(exercice.contenuExo.situation ?? "").font(.subheadline).foregroundStyle(.secondary)
            Text(exercice.contenuExo.replique ?? "").font(.title3).carteMintza()
            boutonsChoix(exercice.contenuExo.choix ?? [])
        case .comprehension_ecrite:
            Text(exercice.contenuExo.texte ?? "").font(.body).lineSpacing(5).carteMintza()
            boutonsChoix(exercice.contenuExo.choix ?? [])
        case .vrai_faux:
            Text(exercice.contenuExo.affirmation ?? "").font(.title3).carteMintza()
            bouton("Vrai", selectionne: valeur == true) { valeur = true }
            bouton("Faux", selectionne: valeur == false) { valeur = false }
        case .association:
            associations(exercice)
        case .ordre_mots:
            ordreMots(exercice)
        }
    }

    private func boutonsChoix(_ elements: [ElementExercice]) -> some View {
        VStack(spacing: 12) {
            ForEach(elements) { element in
                bouton(element.texte, selectionne: choix == element.id) { choix = element.id }
            }
        }
    }

    private func bouton(_ texte: String, selectionne: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(texte).multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: selectionne ? "checkmark.circle.fill" : "circle")
            }.padding(18).frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .background(selectionne ? Color.vertDouxMintza : Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selectionne ? Color.vertMintza : Color.traitMintza, lineWidth: 1))
        }.buttonStyle(.plain).disabled(corrige).accessibilityAddTraits(selectionne ? .isSelected : [])
    }

    private func associations(_ exercice: ExerciceDistant) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Touchez un élément à gauche, puis son correspondant à droite.").font(.subheadline).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(exercice.contenuExo.gauche ?? []) { element in
                        Button { gaucheActive = element.id } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(element.texte)
                                if let droite = paires[element.id], let cible = exercice.contenuExo.droite?.first(where: { $0.id == droite }) {
                                    Text("→ \(cible.texte)").font(.caption).foregroundStyle(Color.vertMintza)
                                }
                            }.frame(maxWidth: .infinity, minHeight: 64, alignment: .leading).padding(12)
                                .background(gaucheActive == element.id ? Color.vertDouxMintza : Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(gaucheActive == element.id ? Color.vertMintza : Color.traitMintza))
                        }.buttonStyle(.plain).disabled(corrige)
                            .accessibilityAddTraits(gaucheActive == element.id ? .isSelected : [])
                    }
                }.frame(maxWidth: .infinity)
                VStack(spacing: 12) {
                    ForEach(exercice.contenuExo.droite ?? []) { element in
                        Button {
                            guard let gaucheActive else { return }
                            // Réattribuer une carte libère sa précédente association.
                            paires = paires.filter { $0.value != element.id && $0.key != gaucheActive }
                            paires[gaucheActive] = element.id
                            self.gaucheActive = nil
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(element.texte)
                                if paires.values.contains(element.id) { Image(systemName: "link").foregroundStyle(Color.vertMintza) }
                            }.frame(maxWidth: .infinity, minHeight: 64, alignment: .leading).padding(12)
                                .background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain).disabled(corrige || gaucheActive == nil)
                    }
                }.frame(maxWidth: .infinity)
            }
            Text("\(paires.count) / \(exercice.contenuExo.gauche?.count ?? 0) associations").font(.caption).foregroundStyle(.secondary)
            Button("Recommencer les associations") { paires = [:]; gaucheActive = nil }.disabled(corrige || paires.isEmpty)
        }
    }

    private func ordreMots(_ exercice: ExerciceDistant) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Touchez les groupes dans l’ordre. Touchez un groupe choisi pour le retirer.").font(.subheadline).foregroundStyle(.secondary)
            if ordre.isEmpty { Text("Votre phrase apparaîtra ici.").foregroundStyle(.secondary).carteMintza() }
            ForEach(Array(ordre.enumerated()), id: \.element) { position, identifiant in
                if let mot = exercice.contenuExo.mots?.first(where: { $0.id == identifiant }) {
                    Button { ordre.removeAll { $0 == identifiant } } label: {
                        HStack { Text("\(position + 1).").foregroundStyle(.secondary); Text(mot.texte); Spacer(); Image(systemName: "minus.circle") }
                            .padding(14).background(Color.vertDouxMintza, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain).disabled(corrige).accessibilityLabel("Retirer \(mot.texte)")
                }
            }
            ForEach((exercice.contenuExo.mots ?? []).filter { !ordre.contains($0.id) }) { mot in
                bouton(mot.texte, selectionne: false) { ordre.append(mot.id) }
            }
            Button("Tout effacer") { ordre = [] }.disabled(corrige || ordre.isEmpty)
        }
    }

    private func avancer() {
        guard let exercice else { return }
        if corrige {
            if index + 1 == exercices.count { termine = true; enregistrer() }
            else { index += 1; effacerReponse() }
        } else if reponseComplete {
            bonneReponse = exercice.estCorrect(choix: choix, valeur: valeur, paires: paires, ordre: ordre)
            if bonneReponse { score += 1 }
            corrige = true
        }
    }

    private func effacerReponse() {
        choix = nil; valeur = nil; paires = [:]; gaucheActive = nil; ordre = []
        corrige = false; bonneReponse = false
    }

    private func enregistrer() {
        guard !sauvegarde else { return }
        do {
            try magasin.terminer(lecon, score: score, total: exercices.count)
            sauvegarde = true; erreurSauvegarde = nil
        } catch { erreurSauvegarde = error.localizedDescription }
    }

    private var resultat: some View {
        VStack(spacing: 24) {
            Image(systemName: "hands.clap.fill").font(.system(size: 70)).foregroundStyle(Color.vertMintza)
            Text("Oso ongi !").font(.largeTitle.bold())
            Text("\(score) / \(exercices.count)").font(.system(size: 52, weight: .bold, design: .rounded))
            Text("Chaque échange commence par quelques mots.").multilineTextAlignment(.center)
            if let erreurSauvegarde {
                Text(erreurSauvegarde).foregroundStyle(Color.rougeMintza)
                Button("Réessayer la sauvegarde", action: enregistrer)
            } else {
                Text(magasin.profil == nil ? "Mode invité : ce résultat n’est pas enregistré." : "Meilleur résultat enregistré sur cet iPhone.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Button("Recommencer") {
                index = 0; score = 0; termine = false; sauvegarde = false; erreurSauvegarde = nil; effacerReponse()
            }.buttonStyle(.bordered)
            Button { fermer() } label: { Text("Terminer la leçon").frame(maxWidth: .infinity) }.buttonStyle(StyleBoutonCapsulePrincipal())
        }.frame(maxWidth: .infinity).padding(.vertical, 30)
    }
}
