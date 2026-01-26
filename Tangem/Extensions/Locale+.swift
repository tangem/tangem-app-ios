//
//  Locale+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Locale {
    /// Copyright https://github.com/mattt
    /// https://gist.github.com/mattt/6d022b66f08ea8c1b99ebe7e48b95c4b
    func localizedCurrencySymbol(forCurrencyCode currencyCode: String) -> String? {
        switch currencyCode {
        case AppConstants.rubCurrencyCode:
            return AppConstants.rubSign
        case AppConstants.usdCurrencyCode:
            return AppConstants.usdSign
        default:
            break
        }

        guard let languageCode = language.languageCode?.identifier, let regionCode = region?.identifier else { return nil }

        /*
          Each currency can have a symbol ($, £, ¥),
          but those symbols may be shared with other currencies.
          For example, in Canadian and American locales,
          the $ symbol on its own implicitly represents CAD and USD, respectively.
          Including the language and region here ensures that
          USD is represented as $ in America and US$ in Canada.
         */
        let components: [String: String] = [
            NSLocale.Key.languageCode.rawValue: languageCode,
            NSLocale.Key.countryCode.rawValue: regionCode,
            NSLocale.Key.currencyCode.rawValue: currencyCode,
        ]

        let identifier = Locale.identifier(fromComponents: components)

        return Locale(identifier: identifier).currencySymbol
    }
}

extension Locale {
    /// Supported language codes for news-related services.
    private static let supportedNewsLanguageCodes: Set<String> = [
        "en", // English
        "ru", // Russian
        "fr", // French
        "ua", // Ukrainian
        "de", // German
        "ja", // Japanese
        "es", // Spanish
        "tr", // Turkish
        "ko", // Korean
        "zh", // Chinese
        "pt", // Portuguese
    ]

    /// Language code used by news-related services (e.g., `NewsDataProvider`, `CommonMarketsWidgetNewsService`).
    /// Returns the device's preferred language code if it's in the supported list, otherwise returns English.
    static var newsLanguageCode: String {
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return Locale.enLanguageCode
        }

        // preferredLanguages returns identifiers like "ko-KR", "pt-BR", "en-US"
        // We need to extract just the language code (ISO 639-1)
        let language = Locale.Language(identifier: preferredLanguage)
        let languageCode = language.languageCode?.identifier(.alpha2) ?? Locale.enLanguageCode

        // Return the language code only if it's supported, otherwise fallback to English
        return supportedNewsLanguageCodes.contains(languageCode) ? languageCode : Locale.enLanguageCode
    }
}
