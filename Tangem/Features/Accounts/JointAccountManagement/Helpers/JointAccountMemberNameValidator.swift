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
///
/// - Note: Every character is allowed — real names carry hyphens, apostrophes and diacritics, and the name is never
/// normalised anyway, because it goes into the payload the card signs. Validation is a boolean gate on emptiness and
/// length only, the same as on Android.
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
    }
}

// MARK: - Auxiliary types

extension JointAccountMemberNameValidator {
    enum ValidationError: Error, Equatable {
        case empty
        case tooLong
    }
}
