//
//  TangemPayOrderFormValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayOrderFormValidator {
    static func isEmbossCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedEmboss)
    }

    static func isNameCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedName)
    }

    static func isShippingAddressCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedShippingAddress)
    }

    static func isPostalCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedPostal)
    }

    static func isAddressCharsetValid(_ value: String) -> Bool {
        isValid(value, disallowing: Constants.disallowedAddress)
    }

    static func containsNonLatinLetter(_ value: String) -> Bool {
        normalized(value).range(of: Constants.nonLatinLetter, options: .regularExpression) != nil
    }

    static func capped(_ current: String, replacing range: NSRange, with replacement: String, maxLength: Int) -> String? {
        let current = current as NSString
        let replacement = replacement as NSString
        let keptLength = current.length - range.length

        guard keptLength + replacement.length > maxLength else {
            return nil
        }

        let allowance = max(0, maxLength - keptLength)
        return current.replacingCharacters(in: range, with: replacement.substring(to: allowance))
    }
}

private extension TangemPayOrderFormValidator {
    enum Constants {
        static let disallowedEmboss = "[^A-Za-z0-9 .,/#'()&-]"
        static let disallowedName = "[^A-Za-z -]"
        static let disallowedShippingAddress = "[^A-Za-z0-9 .,#'/&()°-]"
        static let disallowedPostal = "[^A-Za-z0-9 -]"
        static let disallowedAddress = "[^\\p{IsLatin}\\p{M}0-9 .,/#'()&-]"
        static let nonLatinLetter = "[\\p{L}\\p{M}&&[^A-Za-z]]"
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
