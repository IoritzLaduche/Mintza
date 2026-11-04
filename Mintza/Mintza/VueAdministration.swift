import SwiftUI

struct VueAdministration: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @State private var filtre: StatutDemande = .attente
    @State private var retrait: CommerceMintza?
    @State private var selection: UUID?
    @State private var erreur: String?
    private var demandes: [DemandeMintza] { magasin.etat.demandes.filter { $0.statut == filtre }.sorted { $0.date > $1.date } }
    var body: some View {
        Group {
            if magasin.estAdmin {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        TitreMintza(titre: "Administration", sousTitre: "Mode démonstration")
                        HStack(spacing: 14) {
                            StatistiqueMintza(valeur: "\(magasin.etat.demandes.filter { $0.statut == .attente }.count)", titre: "En attente", icone: "clock.fill", couleur: .orange)
                            StatistiqueMintza(valeur: "\(magasin.etat.commerces.count)", titre: "Publiés", icone: "checkmark.circle.fill")
                        }
                        Picker("Statut", selection: $filtre) {
                            Text("En attente").tag(StatutDemande.attente)
                            Text("Validées").tag(StatutDemande.validee)
                            Text("Refusées").tag(StatutDemande.refusee)
                        }.pickerStyle(.segmented)
                        if demandes.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "tray").font(.title).foregroundStyle(.secondary)
                                Text("Aucune demande dans cette catégorie.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            }.frame(maxWidth: .infinity).carteMintza()
                        }
                        VStack(spacing: 12) {
                            ForEach(demandes) { demande in
                                Button { withAnimation { selection = selection == demande.id ? nil : demande.id } } label: {
                                    HStack {
                                        LigneCommerce(commerce: demande.commerce)
                                        Image(systemName: selection == demande.id ? "chevron.up" : "chevron.down").font(.caption).foregroundStyle(.secondary)
                                    }.carteMintza()
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(selection == demande.id ? Color.vertMintza : .clear, lineWidth: 1))
                                }.buttonStyle(.plain)
                                if selection == demande.id {
                                    DecisionDemandeMintza(demandeID: demande.id).id(demande.id).carteMintza()
                                }
                            }
                        }
                        DisclosureGroup("Commerces publiés") {
                            VStack(spacing: 14) {
                                ForEach(magasin.etat.commerces) { commerce in
                                    VStack(spacing: 12) {
                                        NavigationLink { VueFormulaireCommerce(commerce: commerce, modificationAdmin: true) } label: { LigneCommerce(commerce: commerce) }.buttonStyle(.plain)
                                        Button("Retirer de la carte", role: .destructive) { retrait = commerce }.font(.caption).frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    Divider()
                                }
                            }.padding(.top, 16)
                        }.font(.headline).carteMintza()
                        DisclosureGroup("Comptes du prototype") {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(magasin.etat.profils) { profil in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(profil.prenom) \(profil.nom)").font(.subheadline.bold())
                                        Text(LocalizedStringKey(profil.role.rawValue)).font(.caption).foregroundStyle(.secondary)
                                        if !profil.email.isEmpty { Text(profil.email).font(.caption) }
                                    }
                                }
                            }.padding(.top, 16).frame(maxWidth: .infinity, alignment: .leading)
                        }.font(.headline).carteMintza()
                    }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
                }.background(Color.fondMintza)
            } else { ContentUnavailableView("Accès réservé", systemImage: "lock.shield", description: Text("Ouvrez le profil Administrateur depuis les accès de démonstration.")) }
        }.navigationTitle("Administration").navigationBarTitleDisplayMode(.inline).erreurMintza($erreur)
            .toolbar(.visible, for: .navigationBar)
            .onChange(of: filtre) { _, _ in selection = nil }
            .confirmationDialog("Retirer \(retrait?.nom ?? "ce commerce") de la carte ?", isPresented: Binding(get: { retrait != nil }, set: { if !$0 { retrait = nil } }), titleVisibility: .visible) {
                Button("Retirer de la carte", role: .destructive) {
                    guard let commerce = retrait else { return }
                    do { try magasin.retirerCommerce(commerce.id) } catch { erreur = error.localizedDescription }
                    retrait = nil
                }
            }
    }
}

struct VueModeration: View {
    let demandeID: UUID
    var body: some View {
        ScrollView { DecisionDemandeMintza(demandeID: demandeID).carteMintza().padding(22) }
            .background(Color.fondMintza).navigationTitle("Examiner la demande").navigationBarTitleDisplayMode(.inline)
    }
}

struct DecisionDemandeMintza: View {
    @EnvironmentObject private var magasin: MagasinMintza
    let demandeID: UUID
    @State private var motif = ""
    @State private var erreur: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if magasin.estAdmin, let demande = magasin.etat.demandes.first(where: { $0.id == demandeID }) {
                Text(demande.commerce.nom).font(.title3.bold())
                LigneDemande(demande: demande)
                Divider()
                InformationsCommerce(commerce: demande.commerce).font(.subheadline)
                if demande.statut == .attente {
                    ChampMintza(titre: "Motif ou message") {
                        TextField("Message au commerçant", text: $motif, axis: .vertical).lineLimit(3...5)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { valider; refuser }
                        VStack(spacing: 12) { valider; refuser }
                    }
                    Text("Un motif est requis en cas de refus.").font(.caption).foregroundStyle(.secondary)
                } else if !demande.motif.isEmpty { Text(demande.motif).font(.subheadline) }
            } else { Text("Demande indisponible ou accès non autorisé.") }
        }.erreurMintza($erreur)
    }
    private var valider: some View {
        Button { traiter(accepter: true) } label: { Text("Valider").frame(maxWidth: .infinity) }.buttonStyle(StyleBoutonCapsulePrincipal())
    }
    private var refuser: some View {
        Button(role: .destructive) { traiter(accepter: false) } label: {
            Text("Refuser").font(.headline).padding(17).frame(maxWidth: .infinity).foregroundStyle(Color.rougeMintza)
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.rougeMintza, lineWidth: 1))
        }.buttonStyle(.plain)
    }
    private func traiter(accepter: Bool) {
        do { try magasin.moderer(demandeID, accepter: accepter, motif: motif) }
        catch { erreur = error.localizedDescription }
    }
}
