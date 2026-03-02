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

    /// Returns the device's preferred language code.
    ///
    /// This method retrieves the list of languages selected by the user in order of preference.
    /// You can choose to include the region code or not.
    ///
    /// - Parameters:
    ///   - withRegion: If `true`, returns the full language identifier including region (e.g., "en-US").
    ///                 If `false`, removes the region part for identifiers with three components (e.g., "zh-Hans-RU" -> "zh-Hans").
    ///   - fallback: The language code to return if the device's language list cannot be determined.
    ///
    /// - Returns: A `String` representing the device language code, with or without region.
    static func deviceLanguageCode(
        withRegion: Bool = true,
        fallback: LanguageCode = .english
    ) -> String {
        // Get the list of device languages in the order set by the user. Format: [language]-[region]
        let languages = CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String]

        // Use fallback if no languages are found
        guard let language = languages?.first else {
            return fallback.identifier
        }

        if withRegion {
            return language
        }

        let separator = "-"
        let languageParts = language.split(separator: separator)

        // We cannot rely on `Locale.language.script` because its standard may differ from the device language identifier
        if languageParts.count > 1 {
            return languageParts.dropLast().joined(separator: separator)
        } else {
            return language
        }
    }
}

public extension Locale {
    static let enLanguageCode = "en"
    static let ruLanguageCode = "ru"
    static let byLanguageCode = "by"
}

public extension Locale {
    static func webLanguageCode() -> String {
        switch deviceLanguageCode() {
        case ruLanguageCode, byLanguageCode:
            return ruLanguageCode
        default:
            return enLanguageCode
        }
    }
}

// MARK: - Supported Language Code

public extension Locale {
    /// Returns supported language code with priority: appLanguage → deviceLanguage → fallback
    static func languageCode(supportedCodes: Set<String>, fallback: String = enLanguageCode) -> String {
        // Priority 1: App language (respects per-app language setting in iOS Settings)
        let appLang = Locale.Language(identifier: appLanguageCode)
        if let code = appLang.languageCode?.identifier(.alpha2), supportedCodes.contains(code) {
            return code
        }

        // Priority 2: Device language
        let deviceLang = Locale.Language(identifier: deviceLanguageCode())
        if let code = deviceLang.languageCode?.identifier(.alpha2), supportedCodes.contains(code) {
            return code
        }

        // Fallback
        return fallback
    }
}
