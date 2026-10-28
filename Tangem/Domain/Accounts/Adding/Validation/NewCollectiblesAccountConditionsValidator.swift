//
//  NewCollectiblesAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct NewCollectiblesAccountConditionsValidator {}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension NewCollectiblesAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountEditError

    func validate() async throws(ValidationError) {
        let message = "A collectibles account is not created through the accounts flow"
        AccountsLogger.warning(message)
        assertionFailure(message)
        throw .unknownError(CommonError.notImplemented)
    }
}
