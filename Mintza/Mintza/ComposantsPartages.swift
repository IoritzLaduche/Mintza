import SwiftUI

extension Color {
    static let vertMintza = Color(red: 0.025, green: 0.46, blue: 0.28)
    static let rougeMintza = Color(red: 0.86, green: 0.10, blue: 0.07)
    static let beigeMintza = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let fondMintza = adaptative(clair: UIColor(red: 0.97, green: 0.955, blue: 0.90, alpha: 1), sombre: UIColor(red: 0.07, green: 0.11, blue: 0.09, alpha: 1))
    static let surfaceMintza = adaptative(clair: UIColor(red: 1, green: 0.995, blue: 0.975, alpha: 1), sombre: UIColor(red: 0.12, green: 0.17, blue: 0.14, alpha: 1))
    static let encreMintza = adaptative(clair: UIColor(red: 0.025, green: 0.16, blue: 0.14, alpha: 1), sombre: UIColor(red: 0.92, green: 0.96, blue: 0.91, alpha: 1))
    static let vertDouxMintza = adaptative(clair: UIColor(red: 0.87, green: 0.93, blue: 0.83, alpha: 1), sombre: UIColor(red: 0.13, green: 0.27, blue: 0.19, alpha: 1))
    static let traitMintza = Color.secondary.opacity(0.15)
    private static func adaptative(clair: UIColor, sombre: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? sombre : clair })
    }
}

struct BasculeLangue: View {
    @AppStorage("langueAppli") private var langueAppli = "fr"
    var body: some View {
        HStack(spacing: 0) {
            bouton("fr", titre: "FR", nom: "Français")
            bouton("eu", titre: "EU", nom: "Euskara")
        }.padding(3).background(Color.surfaceMintza, in: Capsule())
            .overlay(Capsule().stroke(Color.traitMintza, lineWidth: 1))
    }
    private func bouton(_ code: String, titre: String, nom: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { langueAppli = code } } label: {
            Text(LocalizedStringKey(titre)).font(.caption.weight(.semibold)).frame(minWidth: 40, minHeight: 38)
                .background(langueAppli == code ? Color.vertMintza : .clear, in: Capsule())
                .foregroundStyle(langueAppli == code ? .white : Color.encreMintza)
        }.buttonStyle(.plain).accessibilityLabel(LocalizedStringKey(nom))
            .accessibilityAddTraits(langueAppli == code ? .isSelected : [])
    }
}

struct LogoMintza: View {
    var taille: CGFloat = 42
    var body: some View {
        Image("MintzaLogo").resizable().scaledToFit().scaleEffect(1.4)
            .frame(width: taille, height: taille).accessibilityHidden(true)
    }
}

struct VueEnTete: View {
    var body: some View {
        HStack(spacing: 8) {
            LogoMintza()
            Text("MINTZA").font(.system(.title3, design: .rounded, weight: .heavy)).tracking(0.4).foregroundStyle(Color.vertMintza)
            Spacer(minLength: 12)
            BasculeLangue()
        }.padding(.bottom, 2)
    }
}

struct TitreMintza: View {
    let titre: String
    var sousTitre: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titre)).font(.system(.largeTitle, design: .rounded, weight: .bold)).tracking(-0.7)
                .foregroundStyle(Color.encreMintza).fixedSize(horizontal: false, vertical: true)
            if let sousTitre { Text(LocalizedStringKey(sousTitre)).font(.body).foregroundStyle(Color.encreMintza.opacity(0.85)) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StyleBoutonCapsulePrincipal: ButtonStyle {
    @Environment(\.isEnabled) private var actif
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.horizontal, 14).padding(.vertical, 17)
            .frame(minHeight: 52)
            .background(Color.vertMintza.opacity(actif ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 17))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StyleLienMiseEnValeur: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body.weight(.semibold)).foregroundStyle(Color.vertMintza)
            .padding(.vertical, 10).opacity(configuration.isPressed ? 0.6 : 1)
    }
}
struct StyleLienSecondaire: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.callout).foregroundStyle(.secondary).padding(.vertical, 10).opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct IllustrationMintza: View {
    let nom: String
    var hauteur: CGFloat = 220
    var body: some View {
        GeometryReader { geometry in
            Image(nom).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
        }.frame(height: hauteur).accessibilityHidden(true)
    }
}

struct VignetteMintza: View {
    let nom: String
    var taille: CGFloat = 78
    var body: some View {
        Image(nom).resizable().scaledToFill().frame(width: taille, height: taille)
            .clipShape(RoundedRectangle(cornerRadius: 14)).accessibilityHidden(true)
    }
}

struct CarteObjectif: View {
    @EnvironmentObject private var magasin: MagasinMintza
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "target").font(.title2).foregroundStyle(Color.rougeMintza)
                Text("Mon objectif").font(.subheadline.bold())
                Spacer(minLength: 4)
                Text("\(magasin.activiteDuJour) / \(magasin.profil?.objectif ?? 1) leçon(s)").font(.caption)
            }
            ProgressView(value: Double(min(magasin.activiteDuJour, magasin.profil?.objectif ?? 1)), total: Double(magasin.profil?.objectif ?? 1))
                .tint(.vertMintza).scaleEffect(x: 1, y: 1.6, anchor: .center).padding(.bottom, 3)
        }.carteMintza()
    }
}

struct StatistiqueMintza: View {
    let valeur: String
    let titre: String
    let icone: String
    var couleur: Color = .vertMintza
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icone).font(.title3).foregroundStyle(couleur)
            Text(valeur).font(.system(.title2, design: .rounded, weight: .bold))
            Text(LocalizedStringKey(titre)).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ChampMintza<Contenu: View>: View {
    let titre: String
    @ViewBuilder let contenu: () -> Contenu
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(titre)).font(.subheadline.weight(.semibold))
            contenu().padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.traitMintza, lineWidth: 1))
        }
    }
}

extension View {
    func carteMintza() -> some View {
        padding(18).background(Color.surfaceMintza, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    func fondFormulaireMintza() -> some View {
        scrollContentBackground(.hidden).background(Color.fondMintza)
    }
    func erreurMintza(_ erreur: Binding<String?>) -> some View {
        alert("Mintza", isPresented: Binding(get: { erreur.wrappedValue != nil }, set: { if !$0 { erreur.wrappedValue = nil } })) {
            Button("Fermer", role: .cancel) { erreur.wrappedValue = nil }
        } message: { MessageInterface(erreur.wrappedValue ?? "") }
    }
}

extension LeconMintza {
    var illustration: String { id == "cafe" ? "MintzaVocabulaire" : "MintzaAccueil" }
}
