//
//  MobileOnboardingAccessCodeValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MobileOnboardingAccessCodeValidator {
    private static let sequencePattern = #"^(?:012345|123456|234567|345678|456789|567890|678901|789012|890123|"# +
        #"901234|987654|876543|765432|654321|543210|432109|321098|210987|109876|098765)$"#

    func validate(accessCode: String) -> Bool {
        accessCode.range(of: Self.sequencePattern, options: .regularExpression) == nil
    }
}
