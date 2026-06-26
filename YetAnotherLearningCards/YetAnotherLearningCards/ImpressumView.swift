import SwiftUI

struct ImpressumView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private let contactEmail = "5001words@turevskiy.com"
    private var mailtoURL: URL { URL(string: "mailto:\(contactEmail)")! }

    private var contactWebURL: URL {
        let lang = localizationManager.currentLanguage == .automatic
            ? (Locale.current.language.languageCode?.identifier ?? "en")
            : localizationManager.currentLanguage.rawValue
        return URL(string: "https://turevskiy.com/5001words/?lang=\(lang)")!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("About").font(.largeTitle).fontWeight(.bold).padding(.bottom, 8)

                Group {
                    Label("App", systemImage: "app").font(.headline).padding(.top, 8)
                    Text("5001 Words")

                    Label("Version", systemImage: "number").font(.headline).padding(.top, 8)
                    Text(appVersion)

                    Label("Developer", systemImage: "person").font(.headline).padding(.top, 8)
                    Text("Oleksandr Turevskiy")

                    Label("Contact", systemImage: "envelope").font(.headline).padding(.top, 8)
                    Link(contactEmail, destination: mailtoURL)
                        .foregroundStyle(.blue)
                    Link("turevskiy.com/5001words", destination: contactWebURL)
                        .foregroundStyle(.blue).font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
