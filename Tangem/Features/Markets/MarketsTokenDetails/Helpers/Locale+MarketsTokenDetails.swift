//
//  Locale+MarketsTokenDetails.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension Locale {
    /// Supported language codes for the share URL.
    private static let supportedShareLinkLanguageCodes: Set<String> = [
        "en", "es", "pt", "de", "ja", "fr", "tr", "ko", "zh-Hans",
    ]

    /// Language code used for building the share URL.
    static var shareLinkLanguageCode: String {
        for identifier in [appLanguageCode, deviceLanguageCode(withRegion: false)] {
            let language = Locale.Language(identifier: identifier)
            guard let alpha2 = language.languageCode?.identifier(.alpha2) else { continue }

            // Check code with script (e.g. "zh-Hans")
            if let script = language.script {
                let withScript = "\(alpha2)-\(script.identifier.capitalized)"
                if supportedShareLinkLanguageCodes.contains(withScript) {
                    return withScript
                }
            }

            // Check alpha-2 only (e.g. "en")
            if supportedShareLinkLanguageCodes.contains(alpha2) {
                return alpha2
            }
        }

        return enLanguageCode
    }
}
