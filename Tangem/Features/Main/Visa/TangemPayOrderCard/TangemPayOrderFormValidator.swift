//
//  TangemPayOrderFormValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Rain rejects what it cannot print: the shipping address keeps Latin accents, the embossed name is ASCII.
enum TangemPayOrderFormValidator {
    static func isEmbossCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedEmboss)
    }

    static func isAddressCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedAddress)
    }
}

private extension TangemPayOrderFormValidator {
    enum Constants {
        static let disallowedEmboss = "[^A-Za-z0-9 .,/#'()&-]"
        static let disallowedAddress = "[^\\p{IsLatin}\\p{M}0-9 .,/#'()&-]"
    }

    static func isValid(_ value: String, disallowing pattern: String) -> Bool {
        normalized(value).range(of: pattern, options: .regularExpression) == nil
    }

    static func normalized(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
