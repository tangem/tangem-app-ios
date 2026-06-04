//
//  StakingSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

protocol StakingSendAnalyticsLogger: StakingAnalyticsLogger,
    StakingManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendTargetsAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendApproveAnalyticsLogger {
    func setup(stakingTargetsInput: StakingTargetsInput)
    func logNoticeNotEnoughFee()
}

// MARK: - Management Model

protocol StakingManagementModelAnalyticsLogger {
    func logStakingTransactionRejected(error: SendTxError)
    func logStakingTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String)
    func logNoticeUninitializedAddress()
}
