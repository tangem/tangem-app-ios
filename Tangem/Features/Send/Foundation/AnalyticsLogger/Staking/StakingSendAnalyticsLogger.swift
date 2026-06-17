//
//  StakingSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking
import BlockchainSdk

protocol StakingSendAnalyticsLogger: StakeModelAnalyticsLogger,
    StakingAnalyticsLogger,
    StakingManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendTargetsAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendApproveAnalyticsLogger {
    func setup(stakingTargetsInput: StakingTargetsInput)
    func logNoticeUninitializedAddress()
    func logNoticeNotEnoughFee()
    func logErrorSumLimit(errorMessage: String)
}

// MARK: - Management Model

protocol StakingManagementModelAnalyticsLogger {
    func logStakingTransactionRejected(error: SendTxError)
    func logStakingTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String)
    func logNoticeUninitializedAddress()
}

protocol SendTargetsAnalyticsLogger {
    func logStakingTargetChosen()
}
