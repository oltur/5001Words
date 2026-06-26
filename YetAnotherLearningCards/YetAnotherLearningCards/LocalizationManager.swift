import Foundation
import Combine
import SwiftUI
import ObjectiveC

enum AppLanguage: String, CaseIterable, Identifiable {
    // Automatic first, then alphabetically by display name
    case automatic = "auto"
    case albanian = "sq"
    case basque = "eu"
    case bulgarian = "bg"
    case catalan = "ca"
    case croatian = "hr"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case estonian = "et"
    case finnish = "fi"
    case french = "fr"
    case galician = "gl"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case icelandic = "is"
    case irish = "ga"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case latvian = "lv"
    case lithuanian = "lt"
    case norwegian = "nb"
    case polish = "pl"
    case portuguese = "pt"
    case romanian = "ro"
    case scottishGaelic = "gd"
    case slovak = "sk"
    case slovenian = "sl"
    case spanish = "es"
    case swedish = "sv"
    case thai = "th"
    case ukrainian = "uk"
    case welsh = "cy"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .albanian: return "Shqip (Albanian)"
        case .basque: return "Euskara (Basque)"
        case .bulgarian: return "Български (Bulgarian)"
        case .catalan: return "Català (Catalan)"
        case .croatian: return "Hrvatski (Croatian)"
        case .czech: return "Čeština (Czech)"
        case .danish: return "Dansk (Danish)"
        case .dutch: return "Nederlands (Dutch)"
        case .english: return "English"
        case .estonian: return "Eesti (Estonian)"
        case .finnish: return "Suomi (Finnish)"
        case .french: return "Français (French)"
        case .galician: return "Galego (Galician)"
        case .german: return "Deutsch (German)"
        case .greek: return "Ελληνικά (Greek)"
        case .hebrew: return "עברית (Hebrew)"
        case .hindi: return "हिन्दी (Hindi)"
        case .hungarian: return "Magyar (Hungarian)"
        case .icelandic: return "Íslenska (Icelandic)"
        case .irish: return "Gaeilge (Irish)"
        case .italian: return "Italiano (Italian)"
        case .japanese: return "日本語 (Japanese)"
        case .korean: return "한국어 (Korean)"
        case .latvian: return "Latviešu (Latvian)"
        case .lithuanian: return "Lietuvių (Lithuanian)"
        case .norwegian: return "Norsk (Norwegian)"
        case .polish: return "Polski (Polish)"
        case .portuguese: return "Português (Portuguese)"
        case .romanian: return "Română (Romanian)"
        case .scottishGaelic: return "Gàidhlig (Scottish Gaelic)"
        case .slovak: return "Slovenčina (Slovak)"
        case .slovenian: return "Slovenščina (Slovenian)"
        case .spanish: return "Español (Spanish)"
        case .swedish: return "Svenska (Swedish)"
        case .thai: return "ไทย (Thai)"
        case .ukrainian: return "Українська (Ukrainian)"
        case .welsh: return "Cymraeg (Welsh)"
        }
    }

    var locale: Locale {
        if self == .automatic {
            return Locale.current
        }
        return Locale(identifier: rawValue)
    }

    var isRTL: Bool {
        if self == .automatic {
            // iOS 15 compatible way to check language
            return Locale.current.language.languageCode?.identifier == "he"
        }
        return self == .hebrew
    }
}

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguage()
            applyLanguage()
        }
    }

    static var shared = LocalizationManager()
    private let languageKey = "selectedLanguage"

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            currentLanguage = .automatic
        }
        applyLanguage()
    }

    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    private func applyLanguage() {
        if currentLanguage != .automatic {
            Bundle.setLanguage(currentLanguage.rawValue)
        }
    }

    var currentBundle: Bundle {
        if currentLanguage == .automatic {
            return Bundle.main
        }

        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return Bundle.main
    }
}

// Helper function to get localized string with current language
func LocalizedString(_ key: String, comment: String = "") -> String {
    let bundle = LocalizationManager.shared.currentBundle
    return NSLocalizedString(key, bundle: bundle, comment: comment)
}

// Bundle swizzling to override NSLocalizedString
private var bundleKey: UInt8 = 0

class BundleExtension: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ language: String?) {
        defer {
            object_setClass(Bundle.main, BundleExtension.self)
        }

        if let language = language, language != "auto" {
            if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        } else {
            objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
