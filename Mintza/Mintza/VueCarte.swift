import SwiftUI
import MapKit
import CoreLocation
import Combine

extension CommerceMintza {
    var coordonnee: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

@MainActor
final class LocalisationMintza: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var position: CLLocation?
    @Published var erreur: String?
    @Published var recherche = false
    private let gestionnaire = CLLocationManager()
    override init() {
        super.init()
        gestionnaire.delegate = self
        gestionnaire.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    func demander() {
        recherche = true
        switch gestionnaire.authorizationStatus {
        case .notDetermined: gestionnaire.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: gestionnaire.requestLocation()
        case .denied, .restricted:
            recherche = false
            erreur = "La localisation est désactivée. Vous pouvez toujours explorer la carte, ou autoriser Mintza dans les réglages iOS."
        @unknown default: recherche = false
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard recherche else { return }
        if manager.authorizationStatus != .notDetermined { demander() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        position = locations.last
        recherche = false
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        recherche = false
        erreur = "Votre position est indisponible pour le moment. La carte du BAB reste accessible."
    }
}

struct VueCarte: View {
    @AppStorage("langueAppli") private var langueInterface = "fr"
    var racine = false
    @EnvironmentObject private var magasin: MagasinMintza
    @StateObject private var localisation = LocalisationMintza()
    @State private var recherche = ""
    @State private var categorie: CategorieCommerce?
    @State private var favorisSeulement = false
    @State private var selection: UUID?
    @State private var listeOuverte = false
    @State private var camera: MapCameraPosition = .region(Self.regionBAB)
    static let regionBAB = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 43.49, longitude: -1.515), span: MKCoordinateSpan(latitudeDelta: 0.075, longitudeDelta: 0.13))
    private var resultats: [CommerceMintza] {
        magasin.etat.commerces.filter { commerce in
            (categorie == nil || commerce.categorie == categorie) &&
            (!favorisSeulement || magasin.profil?.favoris.contains(commerce.id) == true) &&
            (recherche.isEmpty || "\(commerce.nom) \(commerce.ville) \(commerce.adresse)".localizedStandardContains(recherche))
        }.sorted { $0.nom.localizedStandardCompare($1.nom) == .orderedAscending }
    }
    private var apercu: CommerceMintza? { resultats.first { $0.id == selection } ?? resultats.first }
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                TitreMintza(titre: "Autour de moi")
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Un lieu, une ville…", text: $recherche).font(.subheadline).submitLabel(.search)
                    if !recherche.isEmpty { Button { recherche = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Effacer la recherche") }
                }.padding(13).background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 15))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filtre("Tous", actif: categorie == nil) { categorie = nil }
                        ForEach(CategorieCommerce.allCases) { valeur in filtre(valeur.rawValue, actif: categorie == valeur) { categorie = valeur } }
                        filtre("Favoris", actif: favorisSeulement) { favorisSeulement.toggle() }
                    }
                }
            }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 14)
            carte
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                Text("Lieux « Démo » fictifs. Illustrations d’ambiance.").font(.caption2)
                Spacer(minLength: 0)
            }.foregroundStyle(.secondary).padding(.horizontal, 22).padding(.vertical, 12)
        }.background(Color.fondMintza)
            .navigationTitle("Carte").navigationBarTitleDisplayMode(.inline)
            .toolbar(racine ? .hidden : .visible, for: .navigationBar)
            .onChange(of: localisation.position) { _, position in
                if let position { camera = .region(MKCoordinateRegion(center: position.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04))) }
            }
            .sheet(isPresented: $listeOuverte) {
                NavigationStack {
                    List {
                        ForEach(resultats) { commerce in NavigationLink { VueFicheCommerce(commerceID: commerce.id) } label: { LigneCommerce(commerce: commerce) } }
                        NavigationLink("Référencer mon commerce", destination: VueEspaceCommercant())
                    }.fondFormulaireMintza().navigationTitle("Les Mintzakide")
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { listeOuverte = false } } }
                }.tint(.vertMintza)
            }.erreurMintza($localisation.erreur)
    }
    private var carte: some View {
        Map(position: $camera, selection: $selection) {
            ForEach(resultats) { commerce in
                Marker(commerce.nom, systemImage: commerce.categorie.icone, coordinate: commerce.coordonnee)
                    .tint(commerce.id == apercu?.id ? Color.rougeMintza : Color.vertMintza).tag(commerce.id)
            }
            UserAnnotation()
        }.mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls { MapCompass() }
            .overlay(alignment: .topLeading) {
                Button { listeOuverte = true } label: { Label("\(resultats.count) lieu(x)", systemImage: "list.bullet").font(.caption.bold()).padding(12).background(Color.surfaceMintza, in: Capsule()) }.padding(16)
            }
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Button { localisation.demander() } label: { Image(systemName: "location.fill").frame(width: 44, height: 44) }.disabled(localisation.recherche).accessibilityLabel("Centrer sur ma position")
                    Button { camera = .region(Self.regionBAB) } label: { Image(systemName: "map").frame(width: 44, height: 44) }.accessibilityLabel("Revenir au Pays Basque")
                }.background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 16)).padding(16)
            }
            .overlay(alignment: .bottom) {
                if let commerce = apercu {
                    NavigationLink { VueFicheCommerce(commerceID: commerce.id) } label: {
                        HStack(spacing: 12) { LigneCommerce(commerce: commerce); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.carteMintza()
                    }.buttonStyle(.plain).padding(16)
                } else {
                    VStack(spacing: 8) {
                        Text("Aucun commerce").font(.headline)
                        Text("Essayez une autre recherche ou désactivez un filtre.").font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity).carteMintza().padding(16)
                }
            }
    }
    private func filtre(_ titre: String, actif: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(titre)).font(.caption.weight(.medium)).padding(.horizontal, 17).frame(minHeight: 44)
                .background(actif ? Color.vertMintza : Color.surfaceMintza, in: Capsule())
                .foregroundStyle(actif ? .white : Color.encreMintza)
                .overlay(Capsule().stroke(Color.traitMintza, lineWidth: actif ? 0 : 1))
        }.buttonStyle(.plain).accessibilityAddTraits(actif ? .isSelected : [])
    }
}

struct LigneCommerce: View {
    @AppStorage("langueAppli") private var langueInterface = "fr"
    let commerce: CommerceMintza
    var body: some View {
        HStack(spacing: 12) {
            if commerce.demonstration {
                VignetteMintza(nom: "MintzaCafe", taille: 62)
            } else {
                Image(systemName: commerce.categorie.icone).font(.title2).foregroundStyle(Color.vertMintza)
                    .frame(width: 62, height: 62).background(Color.vertDouxMintza, in: RoundedRectangle(cornerRadius: 14))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(commerce.nom).font(.headline).foregroundStyle(Color.encreMintza)
                Text("\(commerce.ville) · \(TraductionMintza.texte(commerce.categorie.rawValue, langue: langueInterface))").font(.caption).foregroundStyle(.secondary)
                if commerce.demonstration { EtiquetteDemo() }
            }
            Spacer(minLength: 0)
        }
    }
}

struct EtiquetteDemo: View {
    @AppStorage("langueAppli") private var langueInterface = "fr"
    var body: some View {
        Text("Démo").font(.caption2.weight(.medium)).foregroundStyle(Color(red: 0.40, green: 0.24, blue: 0.02))
            .padding(.horizontal, 9).padding(.vertical, 4).background(Color(red: 1, green: 0.91, blue: 0.69), in: Capsule())
            .accessibilityLabel("Commerce fictif de démonstration")
    }
}

struct VueFicheCommerce: View {
    @AppStorage("langueAppli") private var langueInterface = "fr"
    @EnvironmentObject private var magasin: MagasinMintza
    let commerceID: UUID
    @State private var erreur: String?
    private var commerce: CommerceMintza? { magasin.etat.commerces.first { $0.id == commerceID } }
    private var favori: Bool { magasin.profil?.favoris.contains(commerceID) == true }
    var body: some View {
        Group {
            if let commerce {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if commerce.demonstration {
                            IllustrationMintza(nom: "MintzaCafe", hauteur: 220)
                        } else {
                            Map(initialPosition: .region(MKCoordinateRegion(center: commerce.coordonnee, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008))), interactionModes: []) {
                                Marker(commerce.nom, coordinate: commerce.coordonnee).tint(Color.vertMintza)
                            }.frame(height: 220)
                        }
                        VStack(alignment: .leading, spacing: 22) {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(alignment: .top) {
                                    Text(commerce.nom).font(.system(.title, design: .rounded, weight: .bold))
                                    Spacer(minLength: 8)
                                    if commerce.demonstration { EtiquetteDemo() }
                                }
                                Text("\(TraductionMintza.texte(commerce.categorie.rawValue, langue: langueInterface)) · \(commerce.ville)").foregroundStyle(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 14) {
                                Label("\(commerce.adresse), \(commerce.ville)", systemImage: "mappin.and.ellipse")
                                Label(commerce.horaires, systemImage: "clock")
                                if !commerce.telephone.isEmpty { Label(commerce.telephone, systemImage: "phone") }
                            }.font(.subheadline)
                            HStack(alignment: .top, spacing: 16) {
                                LogoMintza(taille: 38).padding(.top, 4)
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("Ici, on parle euskara").font(.headline)
                                    Text(commerce.pratique).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Color.vertDouxMintza.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Un mot utile").font(.subheadline.weight(.medium))
                                HStack(spacing: 14) {
                                    Image(systemName: "bubble.left.and.bubble.right").font(.title2).foregroundStyle(Color.vertMintza)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(commerce.categorie == .cafe ? "Kafe bat, mesedez" : "Kaixo! Eskerrik asko!").font(.headline)
                                        Text(commerce.categorie == .cafe ? "Un café, s’il vous plaît" : "Bonjour ! Merci !").font(.caption).foregroundStyle(.secondary)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading).carteMintza()
                            }
                            NavigationLink { VueApprentissage() } label: { Label("Réviser avant ma visite", systemImage: "book.fill").frame(maxWidth: .infinity) }.buttonStyle(StyleBoutonCapsulePrincipal())
                            if !commerce.demonstration {
                                Button {
                                    let lieu = MKMapItem(location: CLLocation(latitude: commerce.latitude, longitude: commerce.longitude), address: nil)
                                    lieu.name = commerce.nom
                                    lieu.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
                                } label: { Label("Itinéraire dans Plans", systemImage: "arrow.triangle.turn.up.right.diamond").frame(maxWidth: .infinity) }.padding(.vertical, 8)
                            } else { Text("Lieu fictif · Illustration d’ambiance générée.").font(.caption2).foregroundStyle(.secondary) }
                        }.padding(.horizontal, 22).padding(.bottom, 24)
                    }.frame(maxWidth: 620).frame(maxWidth: .infinity)
                }.background(Color.fondMintza)
            } else {
                ContentUnavailableView("Fiche indisponible", systemImage: "storefront", description: Text("Ce commerce a été retiré de la carte."))
            }
        }.navigationTitle("Commerce").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(Color.fondMintza, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let commerce {
                        Button { do { try magasin.basculerFavori(commerce) } catch { erreur = error.localizedDescription } } label: {
                            Image(systemName: favori ? "heart.fill" : "heart").foregroundStyle(Color.rougeMintza).frame(width: 44, height: 44)
                        }.accessibilityLabel(LocalizedStringKey(favori ? "Retirer des favoris" : "Ajouter aux favoris"))
                    }
                }
            }.erreurMintza($erreur)
    }
}
