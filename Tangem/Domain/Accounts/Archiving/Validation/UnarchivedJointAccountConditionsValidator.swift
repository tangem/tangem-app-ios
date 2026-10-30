//
//  UnarchivedJointAccountConditionsValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct UnarchivedJointAccountConditionsValidator {
    let remoteState: CryptoAccountsRemoteState
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension UnarchivedJointAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountRecoveryError

    func validate() async throws(ValidationError) {
        guard !AccountModelUtils.isAccountsLimitReached(for: .joint, in: remoteState) else {
            AccountsLogger.warning("The number of joint accounts exceeded the limit")
            throw .tooManyAccounts
        }
    }
}
