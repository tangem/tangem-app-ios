//
//  StakingBalance.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingBalance: Hashable {
    public let item: StakingTokenItem
    public let amount: Decimal
    public let accountAddress: String?
    public let balanceType: StakingBalanceType
    public let targetType: StakingTargetType
    public let inProgress: Bool
    public let actions: [StakingPendingActionInfo]
    public let actionConstraints: [StakingPendingActionConstraint]?

    public init(
        item: StakingTokenItem,
        amount: Decimal,
        accountAddress: String? = nil,
        balanceType: StakingBalanceType,
        targetType: StakingTargetType,
        inProgress: Bool,
        actions: [StakingPendingActionInfo],
        actionConstraints: [StakingPendingActionConstraint]? = nil
    ) {
        self.item = item
        self.amount = amount
        self.accountAddress = accountAddress
        self.balanceType = balanceType
        self.targetType = targetType
        self.inProgress = inProgress
        self.actions = actions
        self.actionConstraints = actionConstraints
    }
}

public extension Array where Element == StakingBalance {
    /// All staked / blocked balances that were received from the blockchain
    func blocked() -> Self {
        filter { $0.balanceType != .pending && !$0.inProgress }
    }

    /// The balance of "stakes" includes the `pending` balance from the local cache
    /// DO NOT use it to calculate the all balance. It can affect the balance, more that there is
    func stakes() -> Self {
        filter { $0.balanceType != .rewards }
    }

    func rewards() -> Self {
        filter { $0.balanceType == .rewards }
    }

    func sum() -> Decimal {
        reduce(.zero) { $0 + $1.amount }
    }

    func apy(fallbackAPY: Decimal) -> Decimal {
        let rewardRates = compactMap { balance -> Decimal? in
            guard case .active = balance.balanceType else { return nil }
            return balance.targetType.target?.rewardRate
        }

        guard !rewardRates.isEmpty else { // all the balances are in unstaking/unstaked state
            return fallbackAPY
        }

        return rewardRates.sum() / Decimal(rewardRates.count)
    }
}
