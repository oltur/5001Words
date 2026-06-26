import SwiftUI

struct PrivacyPolicyView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    private var privacyWebURL: URL {
        let lang = localizationManager.currentLanguage == .automatic
            ? (Locale.current.language.languageCode?.identifier ?? "en")
            : localizationManager.currentLanguage.rawValue
        return URL(string: "https://turevskiy.com/5001words/privacy?lang=\(lang)")!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy").font(.largeTitle).fontWeight(.bold)

                Group {
                    Text("Data Storage").font(.headline)
                    Text("All your progress and settings are stored locally on your device only. No data is transmitted to external servers or third parties.")

                    Text("Data Collection").font(.headline).padding(.top, 4)
                    Text("We do not collect, store, or share any personal information. The app only saves your learned words and preferences locally on your device.")

                    Text("Audio Downloads").font(.headline).padding(.top, 4)
                    Text("Language packs (word lists and audio) are downloaded from GitHub Releases and stored locally. No account or personal information is required.")

                    Text("Data Control").font(.headline).padding(.top, 4)
                    Text("You have full control over your data. You can reset all progress or remove downloaded packs at any time through Settings.")

                    Text("No Third-Party Tracking").font(.headline).padding(.top, 4)
                    Text("This app contains no ads, no analytics, and no third-party tracking SDKs.")

                    Text("Contact").font(.headline).padding(.top, 4)
                    Link("5001words@turevskiy.com", destination: URL(string: "mailto:5001words@turevskiy.com")!)
                        .foregroundStyle(.blue)
                    Link("Full privacy policy online", destination: privacyWebURL)
                        .foregroundStyle(.blue).font(.caption)
                }
                .font(.body)
                .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
