//
//  DeeplinkRules.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What a value has to look like to be worth handling. Shared by the query reader and by the parsers that
/// take an identifier out of a link's path.
enum DeeplinkRules {
    /// The value as is, or `nil` when it carries characters no identifier of ours ever has.
    static func identifier(_ value: String) -> String? {
        value.range(of: Constants.allowedCharactersRegex, options: .regularExpression) != nil ? value : nil
    }

    static func number(_ value: String) -> Int? {
        guard value.range(of: Constants.numericRegex, options: .regularExpression) != nil else {
            return nil
        }

        return Int(value)
    }
}

// MARK: - Constants

private extension DeeplinkRules {
    enum Constants {
        static let allowedCharactersRegex = "^[a-zA-Z0-9-_@\\.]+$"
        static let numericRegex = "^[0-9]+$"
    }
}
