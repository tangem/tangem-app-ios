//
//  ValidatingTransactionDispatcherProviderDecorator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

struct ValidatingTransactionDispatcherProviderDecorator: TransactionDispatcherProvider {
    private let decoratee: TransactionDispatcherProvider
    private let stakingValidator: StakingTransactionValidator?

    init(decoratee: TransactionDispatcherProvider, stakingValidator: StakingTransactionValidator?) {
        self.decoratee = decoratee
        self.stakingValidator = stakingValidator
    }

    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher {
        let dispatcher = decoratee.makeStakingTransactionDispatcher(analyticsLogger: analyticsLogger)
        return ValidatingStakingTransactionDecorator(decoratee: dispatcher, validator: stakingValidator)
    }

    func makeTransferTransactionDispatcher() -> TransactionDispatcher { decoratee.makeTransferTransactionDispatcher() }
    func makeApproveTransactionDispatcher() -> TransactionDispatcher { decoratee.makeApproveTransactionDispatcher() }
    func makeDEXTransactionDispatcher() -> TransactionDispatcher { decoratee.makeDEXTransactionDispatcher() }
    func makeCEXTransactionDispatcher() -> TransactionDispatcher { decoratee.makeCEXTransactionDispatcher() }
    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher { decoratee.makeYieldModuleTransactionDispatcher() }
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher { decoratee.makeApproveAndDEXTransactionDispatcher() }
}
