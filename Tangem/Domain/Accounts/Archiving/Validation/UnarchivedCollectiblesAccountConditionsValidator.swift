//
//  UnarchivedCollectiblesAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct UnarchivedCollectiblesAccountConditionsValidator {}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension UnarchivedCollectiblesAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountRecoveryError

    func validate() async throws(ValidationError) {
        let message = "A collectibles account is not restored through the accounts flow"
        AccountsLogger.warning(message)
        assertionFailure(message)
        throw .unknownError(CommonError.notImplemented)
    }
}
