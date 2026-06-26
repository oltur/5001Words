import SwiftUI

@main
struct YetAnotherLearningCardsApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared

    private var appLocale: Locale {
        guard localizationManager.currentLanguage != .automatic else { return .current }
        return Locale(identifier: localizationManager.currentLanguage.rawValue)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationManager)
                .environment(\.locale, appLocale)
        }
    }
}
