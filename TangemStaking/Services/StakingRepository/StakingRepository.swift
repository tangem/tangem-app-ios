//
//  StakingRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingRepository {
    var enabledYieldsPublisher: AnyPublisher<[YieldInfo], Never> { get }
    var balancesPublisher: AnyPublisher<[BalanceInfo], Never> { get }

    func updateEnabledYields(withReload: Bool)
    func updateBalances(item: StakingTokenItem, address: String)

    func getYield(item: StakingTokenItem) -> YieldInfo?
    func getBalance(item: StakingTokenItem) -> BalanceInfo?
}
