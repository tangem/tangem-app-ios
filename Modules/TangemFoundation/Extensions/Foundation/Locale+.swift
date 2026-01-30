//
//  Locale+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension Locale {
    /// See https://developer.apple.com/documentation/foundation/nsdateformatter#2528261 for details.
    static let posixEnUS = Locale(identifier: "en_US_POSIX")
}

public extension Locale {
    static let appLanguageCode = Bundle.main.preferredLocalizations.first ?? enLanguageCode

    static let deviceLanguageCode = {
        let languages = CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String]
        return languages?.first ?? LanguageCode.english.identifier
    }()
}

public extension Locale {
    static let enLanguageCode = "en"
    static let ruLanguageCode = "ru"
    static let byLanguageCode = "by"
}

public extension Locale {
    static func webLanguageCode() -> String {
        switch deviceLanguageCode {
        case ruLanguageCode, byLanguageCode:
            return ruLanguageCode
        default:
            return enLanguageCode
        }
    }

    /// Returns supported language code with priority: appLanguage → deviceLanguage → fallback
    static func languageCode(supportedCodes: Set<String>, fallback: String = enLanguageCode) -> String {
        // Priority 1: App language (respects per-app language setting in iOS Settings)
        let appLang = Locale.Language(identifier: appLanguageCode)
        if let code = appLang.languageCode?.identifier(.alpha2), supportedCodes.contains(code) {
            return code
        }

        // Priority 2: Device language
        let deviceLang = Locale.Language(identifier: deviceLanguageCode)
        if let code = deviceLang.languageCode?.identifier(.alpha2), supportedCodes.contains(code) {
            return code
        }

        // Fallback
        return fallback
    }
}

// MARK: - News Language Code

public extension Locale {
    /// Supported language codes for news-related services.
    private static let supportedNewsLanguageCodes: Set<String> = [
        "en", "ru", "fr", "uk", "de", "ja", "es", "tr", "ko", "zh", "pt",
    ]

    /// Language code used by news-related services.
    /// Returns the app's language code if it's in the supported list, otherwise returns English.
    /// Priority: 1) App language (set in iOS Settings → App → Language), 2) Device language
    static var newsLanguageCode: String {
        let language = Locale.Language(identifier: appLanguageCode)
        let languageCode = language.languageCode?.identifier(.alpha2) ?? enLanguageCode
        return supportedNewsLanguageCodes.contains(languageCode) ? languageCode : enLanguageCode
    }
}
