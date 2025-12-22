//
//  MobileOnboardingAccessCodeValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MobileOnboardingAccessCodeValidator {
    /// Sequence with same repeated digit
    private static let repeatedDigitPattern = #"^(\d)\1{5}$"#

    /// Ascending strictly digit sequence
    private static let ascendingSequencePattern = #"^(012345|123456|234567|345678|456789)$"#

    /// Descending strictly digit sequence
    private static let descendingSequencePattern = #"^(987654|876543|765432|654321|543210)$"#

    func validate(accessCode: String) -> Bool {
        validate(accessCode, pattern: Self.repeatedDigitPattern) &&
            validate(accessCode, pattern: Self.ascendingSequencePattern) &&
            validate(accessCode, pattern: Self.descendingSequencePattern)
    }

    private func validate(_ string: String, pattern: String) -> Bool {
        string.range(of: pattern, options: .regularExpression) == nil
    }
}
