//
//  TransactionDispatcherProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol TransactionDispatcherProvider {
    func makeTransferTransactionDispatcher() -> TransactionDispatcher
    func makeApproveTransactionDispatcher() -> TransactionDispatcher
    func makeDEXTransactionDispatcher() -> TransactionDispatcher
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher
    func makeCEXTransactionDispatcher() -> TransactionDispatcher
    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher
    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher
}

enum TransactionDispatcherProviderError: LocalizedError {
    case transactionNotSupported(reason: String)

    var errorDescription: String? {
        switch self {
        case .transactionNotSupported(reason: let reason): "Transaction not supported with reason: \(reason)"
        }
    }
}
