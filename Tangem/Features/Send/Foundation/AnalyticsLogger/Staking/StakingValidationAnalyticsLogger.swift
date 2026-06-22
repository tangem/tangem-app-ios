//
//  StakingValidationAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol StakingValidationAnalyticsLogger: AnyObject {
    func logScamVerification(error: StakingTransactionValidationError?)
}
