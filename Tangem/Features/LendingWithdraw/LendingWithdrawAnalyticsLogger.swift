//
//  LendingWithdrawAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
struct LendingWithdrawAnalyticsLogger {}

// MARK: - FeeSelectorAnalytics

extension LendingWithdrawAnalyticsLogger: FeeSelectorAnalytics {
    func logFeeStepOpened() {}
    func logFeeSelected(tokenFee: TokenFee) {}
    func logFeeSelected(_ feeOption: FeeOption) {}
    func logFeeSummaryOpened() {}
    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {}
    func logCustomFeeClicked() {}
}
