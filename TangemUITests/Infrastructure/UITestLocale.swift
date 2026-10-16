//
//  UITestLocale.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum UITestLocale {
    static let language = "en"
    static let region = "US"

    static var identifier: String {
        "\(language)_\(region)"
    }

    static var locale: Locale {
        Locale(identifier: identifier)
    }

    static var launchArguments: [String] {
        ["-AppleLocale", identifier, "-AppleLanguages", "(\(language))"]
    }
}
