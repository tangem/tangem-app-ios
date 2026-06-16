//
//  AddressBookContactName.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validated contact name. Illegal names are unrepresentable: the only way to build one from raw
/// user input is `init(validating:)`, which enforces the product rules — 1...50 characters after
/// trimming and no emoji, line breaks, tabs, invisible characters or HTML. Uniqueness within a
/// wallet is enforced separately by the manager.
struct AddressBookContactName: Hashable {
    static let maxLength = 50

    let value: String

    init(validating raw: String) throws {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw AddressBookValidationError.nameEmpty
        }

        guard trimmed.count <= Self.maxLength else {
            throw AddressBookValidationError.nameTooLong
        }

        guard !Self.containsForbiddenCharacters(trimmed) else {
            throw AddressBookValidationError.nameContainsForbiddenCharacters
        }

        value = trimmed
    }

    private static func containsForbiddenCharacters(_ string: String) -> Bool {
        for scalar in string.unicodeScalars {
            // HTML / script
            if scalar == "<" || scalar == ">" {
                return true
            }

            // Line breaks, tabs and other control characters
            if CharacterSet.controlCharacters.contains(scalar) {
                return true
            }

            // Invisible / formatting characters (zero-width joiners, BOM, directional marks, ...)
            if scalar.properties.generalCategory == .format {
                return true
            }

            // Emoji. Digits and ASCII punctuation that merely *can* form emoji are allowed.
            if scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && scalar.value > 0x2100) {
                return true
            }
        }

        return false
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
