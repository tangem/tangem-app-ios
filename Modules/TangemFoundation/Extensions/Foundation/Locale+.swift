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
