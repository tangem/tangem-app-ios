//
//  ArchivedCryptoAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ArchivedCryptoAccountConditionsValidator {
    let identifier: any AccountModelPersistentIdentifierConvertible

    func isValid() async -> Bool {
        guard !identifier.isMainAccount else {
            // Main account cannot be archived by definition
            return false
        }

        guard await !participatesInReferralProgram() else {
            // Account participates in an active referral program
            return false
        }

    }

    private func participatesInReferralProgram() async -> Bool {
        // [REDACTED_TODO_COMMENT]
        return false
    }
}
