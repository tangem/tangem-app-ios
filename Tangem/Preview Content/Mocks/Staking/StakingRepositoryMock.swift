//
//  StakingRepositoryMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import Combine

struct StakingRepositoryMock: StakingRepository {
    var enabledYieldsPublisher: AnyPublisher<[TangemStaking.YieldInfo], Never> {
        .just(output: [.mock])
    }

    var balancesPublisher: AnyPublisher<[StakingBalanceInfo], Never> { .just(output: []) }

    func updateEnabledYields(withReload: Bool) {}

    func updateBalances(item: TangemStaking.StakingTokenItem, address: String) {}

    func getYield(item: TangemStaking.StakingTokenItem) -> TangemStaking.YieldInfo? {
        .mock
    }

    func getBalance(item: TangemStaking.StakingTokenItem) -> StakingBalanceInfo? {
        .none
    }
}
