import SwiftUI

private enum OngletMintza: Int, CaseIterable {
    case accueil, apprendre, carte, profil
    var titre: String {
        switch self { case .accueil: "Accueil"; case .apprendre: "Apprendre"; case .carte: "Carte"; case .profil: "Profil" }
    }
    var icone: String {
        switch self { case .accueil: "house"; case .apprendre: "book"; case .carte: "mappin.circle"; case .profil: "person.crop.circle" }
    }
}

struct ContentView: View {
    @AppStorage("langueAppli") private var langueAppli = "fr"
    @StateObject private var magasin = MagasinMintza()
    @StateObject private var catalogue = CatalogueDistant()
    @State private var onglet: OngletMintza = .accueil

    var body: some View {
        TabView(selection: $onglet) {
            NavigationStack { VueAccueil() }.tag(OngletMintza.accueil).toolbar(.hidden, for: .tabBar)
            NavigationStack { VueApprentissageDistant(racine: true) }.tag(OngletMintza.apprendre).toolbar(.hidden, for: .tabBar)
            NavigationStack { VueCarte(racine: true) }.tag(OngletMintza.carte).toolbar(.hidden, for: .tabBar)
            NavigationStack { VueConnexion(racine: true) }.id(magasin.profil?.id).tag(OngletMintza.profil).toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { barreOnglets }
        .tint(.vertMintza)
        .foregroundStyle(Color.encreMintza)
        .environmentObject(magasin)
        .environmentObject(catalogue)
        .task { await catalogue.charger() }
        .environment(\.locale, Locale(identifier: langueAppli))
        .alert("Stockage local", isPresented: Binding(get: { magasin.erreurStockage != nil }, set: { if !$0 { magasin.erreurStockage = nil } })) {
            Button("Fermer", role: .cancel) { magasin.erreurStockage = nil }
        } message: { Text(magasin.erreurStockage ?? "") }
    }

    private var barreOnglets: some View {
        HStack(spacing: 0) {
            ForEach(OngletMintza.allCases, id: \.rawValue) { item in
                Button { onglet = item } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icone + (onglet == item ? ".fill" : "")).font(.system(size: 22, weight: .regular))
                        Text(LocalizedStringKey(item.titre)).font(.caption2.weight(onglet == item ? .semibold : .regular))
                    }.frame(maxWidth: .infinity).frame(minHeight: 55)
                        .foregroundStyle(onglet == item ? Color.vertMintza : Color.secondary)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityAddTraits(onglet == item ? .isSelected : [])
                    .accessibilityIdentifier("onglet-\(item.rawValue)")
            }
        }.padding(.horizontal, 12).padding(.top, 5)
            .background(Color.surfaceMintza.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Color.traitMintza.frame(height: 0.5) }
    }
}
