//
//  TangemPayVisaBenefitsURLBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TangemPayVisaBenefitsURLBuilder {
    func url() -> URL? {
        URL(string: "https://tangem.com/\(Self.webLocalePath(for: Locale.appLanguageCode))/tangem-pay/visa-benefits/")
    }

    private static func webLocalePath(for appLanguageCode: String) -> String {
        switch appLanguageCode {
        case "es": "es"
        case "pt-BR", "pt": "pt"
        case "ja": "ja"
        case "zh-Hans": "zh-Hans"
        case "fr": "fr"
        case "de": "de"
        default: "en"
        }
    }
}
