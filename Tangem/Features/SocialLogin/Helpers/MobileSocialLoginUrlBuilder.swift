//
//  MobileSocialLoginUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MobileSocialLoginUrlBuilder {
    func learnMoreURL() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tangem.com"
        components.path = Self.helpCenterArticlePath(Self.learnMoreArticlePath)
        components.fragment = Self.learnMoreArticleFragment
        return components.url
    }
}

// MARK: - Path building

private extension MobileSocialLoginUrlBuilder {
    static func helpCenterArticlePath(_ articlePath: String) -> String {
        "/\(webLanguagePath(for: Locale.appLanguageCode))/\(helpCenterPath)/\(articlePath)/"
    }
}

// MARK: - Language mapping

extension MobileSocialLoginUrlBuilder {
    private static func webLanguagePath(for appLanguageCode: String) -> String {
        switch appLanguageCode {
        case "es": "es"
        case "pt", "pt-BR": "pt"
        case "ja": "ja"
        case "zh-Hans": "zh-Hans"
        case "fr": "fr"
        case "de": "de"
        case "uk", "uk-UA": "uk"
        default: "en"
        }
    }
}

// MARK: - Constants

private extension MobileSocialLoginUrlBuilder {
    static let helpCenterPath = "help-center"
    static let learnMoreArticlePath = "getting-started-with-mobile-wallet/how-to-create-a-mobile-wallet"
    static let learnMoreArticleFragment = "create-a-wallet-with-google-or-apple"
}
