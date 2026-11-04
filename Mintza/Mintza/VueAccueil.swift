import SwiftUI
import SwiftUI
import CoreData
struct VueAccueil: View {
    @EnvironmentObject private var magasin: MagasinMintza
    @EnvironmentObject private var catalogue: CatalogueDistant
    private var prochaineLecon: LeconDistante? {
        catalogue.lecons.first { magasin.profil?.resultatsDistants?[String($0.id)] == nil } ?? catalogue.lecons.first
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VueEnTete().padding(.horizontal, 22)
                VStack(alignment: .leading, spacing: 6) {
                    Text(magasin.profil.map { LocalizedStringKey("Kaixo, \($0.prenom) !") } ?? LocalizedStringKey("Kaixo !"))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold)).tracking(-0.8)
                    Text("Quelques mots aujourd’hui.\nUne conversation demain.")
                        .font(.body).lineSpacing(4)
                }.padding(.horizontal, 22)
                VStack(spacing: 0) {
                    IllustrationMintza(nom: "MintzaAccueil", hauteur: 270)
                    if let lecon = prochaineLecon {
                        NavigationLink { VueLeconDistante(lecon: lecon) } label: {
                            HStack { Text(LocalizedStringKey(magasin.nombreLeconsTerminees > 0 ? "Continuer ma leçon" : "Commencer à apprendre")); Spacer(); Image(systemName: "arrow.right") }
                        }.buttonStyle(StyleBoutonCapsulePrincipal())
                            .padding(5).background(Color.fondMintza, in: RoundedRectangle(cornerRadius: 22))
                            .padding(.horizontal, 18).padding(.top, -22)
                    }
                }
                VStack(spacing: 14) {
                    CarteObjectif()
                    HStack(spacing: 12) {
                        NavigationLink { VueApprentissageDistant() } label: {
                            CarteMenu(titre: "Apprendre", sousTitre: "Leçons courtes", icone: "book", couleur: .vertMintza)
                        }
                        NavigationLink { VueCarte() } label: {
                            CarteMenu(titre: "Pratiquer", sousTitre: "Dans les commerces", icone: "mappin.and.ellipse", couleur: .rougeMintza)
                        }
                    }.buttonStyle(.plain)
                    if magasin.profil == nil {
                        NavigationLink("Se connecter pour garder sa progression", destination: VueConnexion())
                            .font(.footnote.weight(.medium)).padding(.vertical, 8)
                    }
                    if magasin.profil?.role == .commercant || magasin.estAdmin {
                        NavigationLink { VueEspaceCommercant() } label: {
                            HStack { Label("Mon espace commerçant", systemImage: "storefront"); Spacer(); Image(systemName: "chevron.right") }.font(.subheadline.weight(.semibold)).carteMintza()
                        }.buttonStyle(.plain)
                    }
                    if magasin.estAdmin {
                        NavigationLink { VueAdministration() } label: {
                            HStack { Label("Administration", systemImage: "checkmark.shield"); Spacer(); Image(systemName: "chevron.right") }.font(.subheadline.weight(.semibold)).carteMintza()
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 22)
            }.padding(.top, 12).padding(.bottom, 20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
        }.background(Color.fondMintza).toolbar(.hidden, for: .navigationBar)
    }
}

struct CarteMenu: View {
    let titre: String
    let sousTitre: String
    let icone: String
    let couleur: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icone).font(.system(size: 26, weight: .medium)).foregroundStyle(couleur)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            Text(LocalizedStringKey(titre)).font(.headline)
            Text(LocalizedStringKey(sousTitre)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading).carteMintza()
    }
}
#Preview("Mintza") {
    ContentView()
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
}
