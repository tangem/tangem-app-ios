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

    static func deviceLanguageCode() -> String {
        if #available(iOS 16, *) {
            return Locale.current.language.languageCode?.identifier ?? LanguageCode.english.identifier
        } else {
            return Locale.current.languageCode ?? enLanguageCode
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
        let languageCode = deviceLanguageCode()
        switch languageCode {
        case ruLanguageCode, byLanguageCode:
            return ruLanguageCode
        default:
            return enLanguageCode
        }
    }
}
