//
//  TangemPayTransactionDispatcherProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

struct TangemPayTransactionDispatcherProvider {
    let transactionDispatcher: any TransactionDispatcher
}

// MARK: - TransactionDispatcherProvider

extension TangemPayTransactionDispatcherProvider: TransactionDispatcherProvider {
    func makeTransferTransactionDispatcher() -> TransactionDispatcher {
        transactionDispatcher
    }

    func makeApproveTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeDEXTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeCEXTransactionDispatcher() -> TransactionDispatcher {
        transactionDispatcher
    }

    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }
}
