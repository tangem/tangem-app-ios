//
//  SendFeeAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendFeeAnalyticsLogger {
    func logFeeSelected(tokenFee: TokenFee)
    func logFeeSelected(_ feeOption: FeeOption)

    func logSendNoticeTransactionDelaysArePossible()
    func logFeeStepOpened()
    func logFeeStepReopened()
    func logFeeSummaryOpened()
    func logFeeTokensOpened(availableTokenFees: [TokenFee])
}
