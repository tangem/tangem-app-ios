//
//  StakingSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

protocol StakingSendAnalyticsLogger: StakeModelAnalyticsLogger,
    StakingManagementModelAnalyticsLogger,
    StakingValidationAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendTargetsAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendApproveAnalyticsLogger {
    func setup(stakingTargetsInput: StakingTargetsInput)
    func logNoticeUninitializedAddress()
    /// - Parameter feeCurrencyBalance: `nil` when the shortage was reported without the balance it was judged against.
    func logNoticeNotEnoughFee(feeCurrencyBalance: Decimal?)
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
