//
//  CollectiblesDepositTransactionDispatcherProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

struct CollectiblesDepositTransactionDispatcherProvider: TransactionDispatcherProvider {
    func makeTransferTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeApproveTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeDEXTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeCEXTransactionDispatcher() -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }

    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher {
        UnsupportedTransactionDispatcher()
    }
}
