//
//  MobileOnboardingAccessCodeValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MobileOnboardingAccessCodeValidator {
    private let weakAccessCodes = [
        "123456", "000000", "012345", "111111", "222222", "333333",
        "444444", "555555", "666666", "777777", "888888", "999999",
        "112233", "223344", "334455", "445566", "556677", "667788",
        "778899", "543210", "654321", "987654", "111222", "222333",
        "333444", "444555", "555666", "666777", "777888", "888999",
        "100000",
    ]

    func validate(accessCode: String) -> Bool {
        !weakAccessCodes.contains(accessCode)
    }
}
