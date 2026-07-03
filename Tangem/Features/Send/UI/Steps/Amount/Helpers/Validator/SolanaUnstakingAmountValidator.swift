//
//  SolanaUnstakingAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class SolanaUnstakingAmountValidator {
    private let stakedAmount: Decimal
    private var minimumAmount: Decimal?
    private var bag = Set<AnyCancellable>()

    init(
        stakedAmount: Decimal,
        stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    ) {
        self.stakedAmount = stakedAmount
        bind(stakingManagerStatePublisher: stakingManagerStatePublisher)
    }

    private func bind(stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>) {
        stakingManagerStatePublisher
            .compactMap { state -> Decimal? in
                switch state {
                case .staked(let staked):
                    let exitMinimum = staked.yieldInfo.exitMinimumRequirement
                    let enterMinimum = staked.yieldInfo.enterMinimumRequirement
                    return exitMinimum > 0 ? exitMinimum : enterMinimum
                default:
                    return nil
                }
            }
            .sink(receiveValue: { [weak self] amount in
                self?.minimumAmount = amount
            })
            .store(in: &bag)
    }
}

extension SolanaUnstakingAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        guard amount > 0 else {
            throw SendAmountValidatorError.zeroAmount
        }

        guard amount <= stakedAmount else {
            throw UnstakingValidationError.amountExceedsStakingBalance
        }

        guard amount != stakedAmount, let minimumAmount else {
            return
        }

        if amount < minimumAmount {
            throw UnstakingValidationError.amountRequirementError(minAmount: minimumAmount)
        }

        if stakedAmount - amount < minimumAmount {
            throw UnstakingValidationError.remainingAmountBelowMinimum
        }
    }
}
