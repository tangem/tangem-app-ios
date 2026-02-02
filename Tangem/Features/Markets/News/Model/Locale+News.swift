//
//  Locale+News.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension Locale {
    /// Supported language codes for news-related services.
    private static let supportedNewsLanguageCodes: Set<String> = [
        "en", "ru", "fr", "uk", "de", "ja", "es", "tr", "ko", "zh", "pt",
    ]

    /// Language code used by news-related services.
    static var newsLanguageCode: String {
        languageCode(supportedCodes: supportedNewsLanguageCodes)
    }
}
