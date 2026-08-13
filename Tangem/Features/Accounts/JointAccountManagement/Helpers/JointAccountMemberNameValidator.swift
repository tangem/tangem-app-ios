//
//  JointAccountMemberNameValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Rules for the name the other members of a joint account see a member by.
struct JointAccountMemberNameValidator {
    static let maxLength = 25

    func validate(_ name: String) throws(ValidationError) {
        // Whitespace makes a name no less blank, even though it is allowed inside one
        guard name.trimmed().isNotEmpty else {
            throw .empty
        }

        guard name.count <= Self.maxLength else {
            throw .tooLong
        }

        guard name.allSatisfy(\.isAllowedInMemberName) else {
            throw .unsupportedCharacters
        }
    }
}

// MARK: - Auxiliary types

extension JointAccountMemberNameValidator {
    enum ValidationError: Error, Equatable {
        case empty
        case tooLong
        case unsupportedCharacters
    }
}

// MARK: - Allowed characters

private extension Character {
    var isAllowedInMemberName: Bool {
        isLetter || isNumber || isWhitespace || isEmoji
    }

    /// `isEmoji` on its own is also true for plain digits and `#`, hence the check for the emoji presentation
    /// and for the variation selector that turns a text glyph into an emoji one.
    private var isEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmojiModifierBase }
            || unicodeScalars.contains { $0.value == Constants.emojiVariationSelector }
    }
}

private extension Character {
    enum Constants {
        static let emojiVariationSelector: UInt32 = 0xFE0F
    }
}
