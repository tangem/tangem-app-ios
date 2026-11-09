//
//  LendingDepositAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

// [REDACTED_TODO_COMMENT]
struct LendingDepositAnalyticsLogger {}

// MARK: - SendManagementModelAnalyticsLogger

extension LendingDepositAnalyticsLogger: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError) {}

    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    ) {}
}

// MARK: - FeeSelectorAnalytics

extension LendingDepositAnalyticsLogger: FeeSelectorAnalytics {
    func logFeeStepOpened() {}
    func logFeeSelected(tokenFee: TokenFee) {}
    func logFeeSelected(_ feeOption: FeeOption) {}
    func logFeeSummaryOpened() {}
    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {}
    func logCustomFeeClicked() {}
}
