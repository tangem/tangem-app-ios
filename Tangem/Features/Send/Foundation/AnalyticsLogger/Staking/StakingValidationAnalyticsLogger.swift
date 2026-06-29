//
//  StakingValidationAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol StakingValidationAnalyticsLogger: AnyObject {
    func logSuccess()
    func logLocalError(_ error: StakingTransactionValidationError)
    func logRemoteError(_ error: RemoteStakingValidationError)
    func logNoRawTransactions()
}
