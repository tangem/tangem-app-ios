//
//  TokensOrder.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Represents an ordered list of accounts with their tokens.
typealias TokensOrder = [(account: String, tokens: [String])]

extension Array where Element == (account: String, tokens: [String]) {
    /// Creates a TokensOrder with a single "main_account" containing the given tokens.
    static func mainAccount(_ tokens: [String]) -> TokensOrder {
        [("main_account", tokens)]
    }

    /// Returns all tokens flattened into a single array, preserving order.
    var allTokensFlat: [String] {
        flatMap { $0.tokens }
    }

    /// Returns tokens for the first account matching the given name.
    func tokens(forAccount account: String) -> [String]? {
        first { $0.account == account }?.tokens
    }

    /// Returns all account names in order.
    var accountNames: [String] {
        map { $0.account }
    }

    /// Converts to dictionary (loses account order, but useful for compatibility).
    var asDictionary: [String: [String]] {
        Dictionary(uniqueKeysWithValues: self)
    }
}
