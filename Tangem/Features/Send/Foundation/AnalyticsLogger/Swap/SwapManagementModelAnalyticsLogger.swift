//
//  SwapManagementModelAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// MARK: - Management Model

protocol SwapManagementModelAnalyticsLogger {
    func logSwapButtonSwap()
    func logSwapButtonTransfer()
    func logSwapTransferModeSwitched()
    func logSwapTransactionSent(result: TransactionDispatcherResult)
    func logSwapPreselectedTokenChanged(
        direction: Analytics.ParameterValue,
        preselectedSymbol: String,
        selectedSymbol: String
    )
}
