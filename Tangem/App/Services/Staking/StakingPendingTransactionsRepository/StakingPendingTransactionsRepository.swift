//
//  StakingPendingTransactionsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol StakingPendingTransactionsRepository {
    var records: [StakingPendingTransactionRecord] { get }

    func transactionDidSent(action: StakingAction, validator: ValidatorInfo?)
    func checkIfConfirmed(balances: [StakingBalanceInfo])
    func hasPending(balance: StakingBalanceInfo) -> Bool
}

private struct StakingPendingTransactionsRepositoryKey: InjectionKey {
    static var currentValue: StakingPendingTransactionsRepository = CommonStakingPendingTransactionsRepository()
}

extension InjectedValues {
    var stakingPendingTransactionsRepository: StakingPendingTransactionsRepository {
        get { Self[StakingPendingTransactionsRepositoryKey.self] }
        set { Self[StakingPendingTransactionsRepositoryKey.self] = newValue }
    }
}
