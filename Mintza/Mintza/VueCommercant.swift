import SwiftUI
import MapKit

struct VueEspaceCommercant: View {
    @EnvironmentObject private var magasin: MagasinMintza
    var body: some View {
        Group {
            if let profil = magasin.profil, profil.role == .commercant || magasin.estAdmin {
                List {
                    Section {
                        Text("Faites vivre l’euskara dans votre commerce.").font(.title3.bold())
                        NavigationLink { VueFormulaireCommerce() } label: { Label("Référencer un commerce", systemImage: "plus.circle.fill") }
                    } footer: { Text("Chaque demande est examinée par l’administration avant publication sur la carte.") }
                    Section("Mes commerces publiés") {
                        if magasin.mesCommerces.isEmpty { Text("Aucun commerce publié pour le moment.").foregroundStyle(.secondary) }
                        ForEach(magasin.mesCommerces) { commerce in
                            NavigationLink { VueFormulaireCommerce(commerce: commerce) } label: { LigneCommerce(commerce: commerce) }
                        }
                    }
                    Section("Suivi de mes demandes") {
                        if magasin.mesDemandes.isEmpty { Text("Vos demandes et leurs réponses apparaîtront ici.").foregroundStyle(.secondary) }
                        ForEach(magasin.mesDemandes) { demande in
                            NavigationLink { VueSuiviDemande(demandeID: demande.id) } label: { LigneDemande(demande: demande) }
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ContentUnavailableView("Rejoindre les Mintzakide", systemImage: "storefront", description: Text("Créez un profil commerçant pour proposer votre lieu et suivre sa validation."))
                    if magasin.profil == nil {
                        NavigationLink("Se connecter ou essayer la démo", destination: VueConnexion())
                    } else {
                        Text("Votre profil actuel est apprenant. Déconnectez-vous dans Profil pour utiliser ou créer un compte commerçant.").multilineTextAlignment(.center)
                    }
                }.padding(24)
            }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("Espace commerçant").navigationBarTitleDisplayMode(.inline)
    }
}

struct LigneDemande: View {
    let demande: DemandeMintza
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(demande.commerce.nom).font(.headline)
            Text(demande.miseAJour ? "Mise à jour de fiche" : "Nouveau référencement").font(.caption).foregroundStyle(.secondary)
            HStack {
                Label(demande.statut.rawValue, systemImage: demande.statut == .attente ? "clock" : demande.statut == .validee ? "checkmark.circle" : "xmark.circle")
                    .foregroundStyle(demande.statut == .refusee ? Color.rougeMintza : .vertMintza)
                Spacer()
                Text(demande.date, style: .date).foregroundStyle(.secondary)
            }.font(.caption)
        }.padding(.vertical, 4)
    }
}

struct VueSuiviDemande: View {
    @EnvironmentObject private var magasin: MagasinMintza
    let demandeID: UUID
    var body: some View {
        List {
            if let demande = magasin.etat.demandes.first(where: { $0.id == demandeID && ($0.auteur == magasin.profil?.id || magasin.estAdmin) }) {
                Section { LigneDemande(demande: demande) }
                Section("Informations transmises") { InformationsCommerce(commerce: demande.commerce) }
                if !demande.motif.isEmpty { Section("Réponse de l’administration") { Text(demande.motif) } }
                if demande.statut == .attente {
                    Section { Text("Votre demande est en attente de validation. Une fiche déjà publiée reste visible avec ses anciennes informations pendant l’examen.") }
                }
                if demande.statut == .refusee && (!demande.miseAJour || magasin.etat.commerces.contains(where: { $0.id == demande.commerce.id })) {
                    Section { NavigationLink("Corriger et soumettre à nouveau") { VueFormulaireCommerce(commerce: demande.commerce, miseAJour: demande.miseAJour) } }
                }
            } else { Text("Demande introuvable.") }
        }.fondFormulaireMintza().toolbar(.visible, for: .navigationBar).navigationTitle("Suivi de demande").navigationBarTitleDisplayMode(.inline)
    }
}

struct InformationsCommerce: View {
    let commerce: CommerceMintza
    var body: some View {
        LabeledContent("Catégorie", value: commerce.categorie.rawValue)
        LabeledContent("Adresse", value: commerce.adresse)
        LabeledContent("Ville", value: commerce.ville)
        LabeledContent("Horaires", value: commerce.horaires)
        if !commerce.telephone.isEmpty { LabeledContent("Téléphone", value: commerce.telephone) }
        Text(commerce.pratique)
        Text("Position : \(commerce.latitude.formatted(.number.precision(.fractionLength(5)))), \(commerce.longitude.formatted(.number.precision(.fractionLength(5))))")
            .font(.caption).foregroundStyle(.secondary)
    }
}

struct VueFormulaireCommerce: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @Environment(\.dismiss) private var dismiss
    @State private var commerce: CommerceMintza
    @State private var emplacementChoisi: Bool
    @State private var carteOuverte = false
    @State private var erreur: String?
    @State private var envoye = false
    let miseAJour: Bool
    let modificationAdmin: Bool

    init(commerce: CommerceMintza? = nil, miseAJour: Bool? = nil, modificationAdmin: Bool = false) {
        _commerce = State(initialValue: commerce ?? CommerceMintza())
        _emplacementChoisi = State(initialValue: commerce != nil)
        self.miseAJour = miseAJour ?? (commerce != nil)
        self.modificationAdmin = modificationAdmin
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    Text("1").font(.caption.bold()).foregroundStyle(.white).frame(width: 27, height: 27).background(Color.vertMintza, in: Circle())
                    Text("Informations").font(.caption.weight(.medium))
                    Rectangle().fill(Color.traitMintza).frame(height: 1)
                    Image(systemName: emplacementChoisi ? "checkmark.circle.fill" : "2.circle.fill").font(.title2).foregroundStyle(emplacementChoisi ? Color.vertMintza : .secondary)
                    Text("Emplacement").font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 8)
                ChampMintza(titre: "Nom du commerce") { TextField("Nom du commerce", text: $commerce.nom) }
                ChampMintza(titre: "Catégorie") {
                    Picker("Catégorie", selection: $commerce.categorie) {
                        ForEach(CategorieCommerce.allCases) { categorie in Label(categorie.rawValue, systemImage: categorie.icone).tag(categorie) }
                    }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                }
                ChampMintza(titre: "Adresse") { TextField("Numéro et rue", text: $commerce.adresse).textContentType(.streetAddressLine1) }
                ChampMintza(titre: "Ville") { TextField("Ville", text: $commerce.ville).textContentType(.addressCity) }
                ChampMintza(titre: "Horaires") { TextField("Lun–sam · 9 h–18 h", text: $commerce.horaires, axis: .vertical).lineLimit(1...3) }
                ChampMintza(titre: "Accueil en euskara") {
                    TextField("Comment peut-on pratiquer l’euskara chez vous ?", text: $commerce.pratique, axis: .vertical).lineLimit(3...6)
                }
                DisclosureGroup("Téléphone (facultatif)") {
                    TextField("Numéro de téléphone", text: $commerce.telephone).keyboardType(.phonePad).padding(.top, 12)
                }.font(.subheadline).carteMintza()
                Button { carteOuverte = true } label: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(emplacementChoisi ? "Modifier l’emplacement" : "Choisir sur la carte").font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: emplacementChoisi ? "checkmark.circle.fill" : "chevron.right")
                    }.carteMintza()
                }.buttonStyle(.plain)
                if emplacementChoisi {
                    Text("Position choisie : \(commerce.latitude.formatted(.number.precision(.fractionLength(5)))), \(commerce.longitude.formatted(.number.precision(.fractionLength(5))))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button {
                    guard emplacementChoisi else { erreur = "Choisissez un emplacement sur la carte."; return }
                    do {
                        if modificationAdmin { try magasin.modifierCommerce(commerce) }
                        else { try magasin.soumettre(commerce, miseAJour: miseAJour) }
                        envoye = true
                    } catch { erreur = error.localizedDescription }
                } label: { Text(modificationAdmin ? "Enregistrer les modifications" : "Envoyer ma demande").frame(maxWidth: .infinity) }
                    .buttonStyle(StyleBoutonCapsulePrincipal()).disabled(envoye)
                Text(modificationAdmin ? "La fiche publiée sera mise à jour immédiatement." : "Publication après validation. L’adresse ne déplace pas automatiquement le repère sur la carte.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.scrollDismissesKeyboard(.interactively).background(Color.fondMintza)
            .navigationTitle("Mon commerce").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(Color.fondMintza, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $carteOuverte) {
                NavigationStack {
                    VueChoixEmplacement(coordonnee: commerce.coordonnee) { coordonnee in
                        commerce.latitude = coordonnee.latitude
                        commerce.longitude = coordonnee.longitude
                        emplacementChoisi = true
                    }
                }
            }
            .erreurMintza($erreur)
            .alert(modificationAdmin ? "Fiche mise à jour" : "Demande envoyée", isPresented: $envoye) {
                Button("Terminé") { dismiss() }
            } message: { Text(modificationAdmin ? "Les modifications sont visibles sur la carte." : "Vous pouvez suivre son état dans votre espace commerçant.") }
    }
}

struct VueChoixEmplacement: View {
    @Environment(\.dismiss) private var dismiss
    @State private var camera: MapCameraPosition
    @State private var centre: CLLocationCoordinate2D
    let choisir: (CLLocationCoordinate2D) -> Void
    init(coordonnee: CLLocationCoordinate2D, choisir: @escaping (CLLocationCoordinate2D) -> Void) {
        _camera = State(initialValue: .region(MKCoordinateRegion(center: coordonnee, span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))))
        _centre = State(initialValue: coordonnee)
        self.choisir = choisir
    }
    var body: some View {
        VStack(spacing: 0) {
            Text("Déplacez la carte pour placer votre commerce sous le repère.").font(.subheadline).padding()
            Map(position: $camera)
                .onMapCameraChange(frequency: .onEnd) { centre = $0.region.center }
                .overlay { Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(Color.vertMintza).allowsHitTesting(false) }
            Button { choisir(centre); dismiss() } label: { Text("Choisir cet emplacement").frame(maxWidth: .infinity) }
                .buttonStyle(StyleBoutonCapsulePrincipal()).padding()
        }.background(Color.fondMintza).navigationTitle("Emplacement").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Annuler") { dismiss() } } }
    }
}
