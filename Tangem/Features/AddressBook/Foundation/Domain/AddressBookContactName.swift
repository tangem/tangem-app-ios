//
//  AddressBookContactName.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A validated contact name. The only ways to obtain one are `AddressBookContactNameValidator` (from
/// raw user input) and `Codable` decoding of the trusted, signed blob — so an unvalidated name cannot
/// be constructed elsewhere. Uniqueness within a wallet is enforced separately by the manager.
struct AddressBookContactName: Hashable {
    let value: String

    var firstLetter: String { "\(value.prefix(1).uppercased())" }

    fileprivate init(value: String) {
        self.value = value
    }
}

extension AddressBookContactName: Codable {
    init(from decoder: Decoder) throws {
        // Names stored inside the signed, encrypted blob are trusted and decoded as-is.
        value = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// Builds a validated `AddressBookContactName` from raw user input, enforcing the product rules —
/// 1...50 characters after trimming; only letters, digits, spaces and emoji are allowed, the same
/// whitelist as on Android.
///
/// Declared in the same file as the model so it can reach the model's `fileprivate` initializer: this
/// makes the validator the only path from raw input to a name, while the model itself carries no
/// validation logic.
struct AddressBookContactNameValidator {
    static let maxLength = 50

    func validate(_ raw: String) throws -> AddressBookContactName {
        if let error = validationError(in: raw) {
            throw error
        }

        return AddressBookContactName(value: raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func validationError(in raw: String) -> AddressBookValidationError? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .nameEmpty
        }

        if trimmed.count > Self.maxLength {
            return .nameTooLong
        }

        if !Self.isMadeOfAllowedCharacters(trimmed) {
            return .nameContainsForbiddenCharacters
        }

        return nil
    }

    private static func isMadeOfAllowedCharacters(_ string: String) -> Bool {
        var containsBaseCharacter = false

        for scalar in string.unicodeScalars {
            switch scalar.properties.generalCategory {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
                 .decimalNumber, .letterNumber, .otherNumber,
                 .otherSymbol:
                containsBaseCharacter = true
            case .nonspacingMark, .spacingMark, .enclosingMark, .modifierSymbol:
                break
            default:
                guard scalar == " " || scalar == "\u{200D}" else {
                    return false
                }
            }
        }

        return containsBaseCharacter
    }
}
