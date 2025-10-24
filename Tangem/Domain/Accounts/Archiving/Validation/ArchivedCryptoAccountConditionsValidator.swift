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

    private func participatesInReferralProgram() async -> Bool {
        // [REDACTED_TODO_COMMENT]
        return false
    }
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension ArchivedCryptoAccountConditionsValidator: CryptoAccountConditionsValidator {
    func validate() async throws {
        guard !identifier.isMainAccount else {
            // Main account cannot be archived by definition
            throw Error.isMainAccount
        }

        guard await !participatesInReferralProgram() else {
            // Account participates in an active referral program
            throw Error.participatesInReferralProgram
        }
    }
}

// MARK: - Auxiliary types

extension ArchivedCryptoAccountConditionsValidator {
    enum Error: Swift.Error {
        case isMainAccount
        case participatesInReferralProgram
    }
}
