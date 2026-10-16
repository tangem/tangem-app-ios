//
//  SwapManagementModelAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Management Model

protocol SwapManagementModelAnalyticsLogger {
    func logSwapButtonSwap(slippage: Decimal?)
    func logSwapSlippageSelectorOpened()
    func logSwapCustomSlippageConfirmed(slippage: Decimal?)
    func logSwapButtonTransfer()
    func logSwapTransferModeSwitched()
    func logSwapTransactionSent(result: TransactionDispatcherResult)
    func logTransferTransactionSent(result: TransactionDispatcherResult)
    func logSwapPreselectedTokenChanged(
        direction: Analytics.ParameterValue,
        preselectedSymbol: String,
        selectedSymbol: String
    )
}
