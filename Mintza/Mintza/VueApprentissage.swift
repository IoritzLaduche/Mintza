import SwiftUI

struct VueApprentissage: View {
    var racine = false
    @EnvironmentObject private var magasin: MagasinMintza
    @State private var niveau = "A1"
    private let niveaux = ["A1", "A2", "B1", "B2", "C1", "C2"]
    private var prochaine: LeconMintza? { LeconMintza.toutes.first { magasin.profil?.scores[$0.id] == nil } ?? LeconMintza.toutes.first }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VueEnTete()
                TitreMintza(titre: "Apprendre", sousTitre: "Vos premiers échanges")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(niveaux, id: \.self) { valeur in
                            Button { niveau = valeur } label: {
                                Text(valeur).font(.subheadline.weight(.medium)).frame(minWidth: 45, minHeight: 44)
                                    .background(niveau == valeur ? Color.vertMintza : Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 16))
                                    .foregroundStyle(niveau == valeur ? .white : .secondary)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.traitMintza, lineWidth: niveau == valeur ? 0 : 1))
                            }.buttonStyle(.plain).accessibilityAddTraits(niveau == valeur ? .isSelected : [])
                        }
                    }
                }
                if niveau == "A1" {
                    VStack(spacing: 14) {
                        ForEach(Array(LeconMintza.toutes.enumerated()), id: \.element.id) { index, lecon in
                            NavigationLink { VueLecon(lecon: lecon) } label: {
                                HStack(spacing: 14) {
                                    VignetteMintza(nom: lecon.illustration, taille: 80)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(String(format: "%02d", index + 1)).font(.caption).foregroundStyle(.secondary)
                                        Text(LocalizedStringKey(lecon.titre)).font(.headline).foregroundStyle(Color.encreMintza)
                                        if let score = magasin.profil?.scores[lecon.id] {
                                            Label("Terminé · \(score)/5", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(Color.vertMintza)
                                        } else {
                                            Text("5 questions · 3 min").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                }.padding(12).background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 20))
                            }.buttonStyle(.plain)
                        }
                    }
                    VStack(alignment: .leading, spacing: 9) {
                        Label("Le mot du jour", systemImage: "lightbulb.fill").font(.subheadline).foregroundStyle(Color.encreMintza)
                        Text("Kaixo").font(.system(.title, design: .rounded, weight: .bold))
                        Text("Bonjour").foregroundStyle(.secondary)
                        if let prochaine {
                            NavigationLink { VueLecon(lecon: prochaine) } label: {
                                HStack { Spacer(); Text("Reprendre"); Image(systemName: "arrow.right"); Spacer() }
                            }.buttonStyle(StyleBoutonCapsulePrincipal()).padding(.top, 3)
                        }
                    }.carteMintza()
                    if magasin.profil == nil {
                        NavigationLink("Enregistrer ma progression", destination: VueConnexion()).font(.footnote).frame(maxWidth: .infinity)
                    }
                } else {
                    ContentUnavailableView("À venir", systemImage: "books.vertical", description: Text("Les leçons du niveau \(niveau) seront ajoutées après le prototype A1."))
                }
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Color.fondMintza).navigationTitle("Apprendre").navigationBarTitleDisplayMode(.inline)
            .toolbar(racine ? .hidden : .visible, for: .navigationBar)
    }
}

struct VueLecon: View {
    let lecon: LeconMintza
    @State private var quizOuvert = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                IllustrationMintza(nom: lecon.illustration, hauteur: 200).clipShape(RoundedRectangle(cornerRadius: 22))
                Label("A1 · Débutant", systemImage: lecon.icone).font(.headline).foregroundStyle(Color.vertMintza)
                Text(LocalizedStringKey(lecon.description)).font(.title2.bold())
                Text("Les mots à retenir").font(.headline)
                VStack(spacing: 0) {
                    ForEach(lecon.mots) { mot in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(mot.basque).font(.title3.bold()).foregroundStyle(Color.vertMintza)
                            Text(mot.francais).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 14)
                        if mot.id != lecon.mots.last?.id { Divider() }
                    }
                }.carteMintza()
                Button { quizOuvert = true } label: {
                    Label("Commencer le quiz", systemImage: "play.fill").frame(maxWidth: .infinity)
                }.buttonStyle(StyleBoutonCapsulePrincipal())
            }.padding(20)
        }.background(Color.fondMintza)
            .navigationTitle(LocalizedStringKey(lecon.titre)).navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .fullScreenCover(isPresented: $quizOuvert) { NavigationStack { VueQuiz(lecon: lecon) }.tint(.vertMintza).foregroundStyle(Color.encreMintza) }
    }
}

struct VueQuiz: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.dismiss) private var dismiss
    let lecon: LeconMintza
    @State private var index = 0
    @State private var selection: Int?
    @State private var corrige = false
    @State private var score = 0
    @State private var termine = false
    @State private var sauvegarde = false
    @State private var erreur: String?
    @State private var quitter = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if termine { resultat }
                else if lecon.questions.indices.contains(index) {
                    let question = lecon.questions[index]
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Question \(index + 1) sur \(lecon.questions.count)").font(.subheadline)
                        ProgressView(value: Double(index + 1), total: Double(lecon.questions.count))
                            .tint(.vertMintza).scaleEffect(x: 1, y: 1.7)
                    }.padding(.top, 20)
                    Text(question.enonce).font(.system(.title, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true).padding(.vertical, 22)
                    VStack(spacing: 14) {
                        ForEach(question.choix.indices, id: \.self) { choix in
                            Button { selection = choix } label: {
                                HStack(spacing: 14) {
                                    Text(question.choix[choix]).font(.body.weight(selection == choix ? .semibold : .regular))
                                    Spacer(minLength: 8)
                                    Image(systemName: corrige && choix == question.reponse ? "checkmark.circle.fill" : corrige && choix == selection ? "xmark.circle.fill" : selection == choix ? "largecircle.fill.circle" : "circle")
                                        .font(.title2).foregroundStyle(couleur(choix, question: question))
                                }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(corrige && choix == question.reponse ? Color.vertDouxMintza : Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 19))
                                    .overlay(RoundedRectangle(cornerRadius: 19).stroke(couleur(choix, question: question), lineWidth: selection == choix || corrige && choix == question.reponse ? 1.6 : 0.7))
                            }.buttonStyle(.plain).disabled(corrige)
                                .accessibilityAddTraits(selection == choix ? .isSelected : [])
                        }
                    }
                    if corrige {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(LocalizedStringKey(selection == question.reponse ? "Bonne réponse !" : "À retenir"), systemImage: selection == question.reponse ? "checkmark.circle.fill" : "lightbulb.fill").font(.headline)
                            Text(question.explication).font(.subheadline)
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.vertDouxMintza, in: RoundedRectangle(cornerRadius: 20))
                            .padding(.top, 20)
                            .accessibilityElement(children: .combine)
                    }
                }
            }.padding(24).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Color.fondMintza)
            .safeAreaInset(edge: .bottom) {
                if !termine {
                    Button(action: avancer) {
                        HStack { Spacer(); Text(LocalizedStringKey(corrige ? (index + 1 == lecon.questions.count ? "Voir mon résultat" : "Question suivante") : "Vérifier")); Image(systemName: "arrow.right"); Spacer() }
                    }.buttonStyle(StyleBoutonCapsulePrincipal()).disabled(selection == nil)
                        .padding(24).background(Color.fondMintza)
                }
            }
            .navigationTitle(LocalizedStringKey(lecon.titre)).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.fondMintza, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { if termine { dismiss() } else { quitter = true } } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Quitter le quiz")
                }
            }
            .confirmationDialog("Quitter le quiz ? Les réponses de cette tentative ne seront pas enregistrées.", isPresented: $quitter, titleVisibility: .visible) {
                Button("Quitter le quiz", role: .destructive) { dismiss() }
            }
    }
    private func avancer() {
        guard lecon.questions.indices.contains(index) else { return }
        if corrige {
            if index + 1 == lecon.questions.count { termine = true; enregistrer() }
            else { index += 1; selection = nil; corrige = false }
        } else if let selection {
            if selection == lecon.questions[index].reponse { score += 1 }
            corrige = true
        }
    }
    private func couleur(_ choix: Int, question: QuestionMintza) -> Color {
        if corrige && choix == question.reponse { return .vertMintza }
        if corrige && choix == selection { return .rougeMintza }
        return selection == choix ? .vertMintza : .traitMintza
    }
    private func enregistrer() {
        guard !sauvegarde else { return }
        do { try magasin.terminer(lecon, score: score); sauvegarde = true; erreur = nil }
        catch { erreur = error.localizedDescription }
    }
    private var resultat: some View {
        VStack(spacing: 24) {
            Image(systemName: score >= 4 ? "star.circle.fill" : "hands.clap.fill").font(.system(size: 80)).foregroundStyle(Color.vertMintza)
            Text(LocalizedStringKey(score >= 4 ? "Oso ongi !" : "Continuez comme ça !")).font(.system(.largeTitle, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
            Text("\(score) / \(lecon.questions.count)").font(.system(size: 56, weight: .bold, design: .rounded))
            Text("Chaque échange commence par quelques mots.").multilineTextAlignment(.center).foregroundStyle(.secondary)
            if let erreur { MessageInterface(erreur).foregroundStyle(Color.rougeMintza); Button("Réessayer la sauvegarde", action: enregistrer) }
            else if magasin.profil != nil { Text("Meilleur score conservé · \(magasin.xp) XP au total").font(.subheadline) }
            else { Text("Mode invité : ce résultat n’est pas enregistré.").font(.subheadline) }
            Button("Recommencer") { index = 0; selection = nil; corrige = false; score = 0; termine = false; sauvegarde = false; erreur = nil }
                .buttonStyle(.bordered)
            Button { dismiss() } label: { Text("Terminer la leçon").frame(maxWidth: .infinity) }.buttonStyle(StyleBoutonCapsulePrincipal())
        }.frame(maxWidth: .infinity).padding(.vertical, 30)
    }
}
