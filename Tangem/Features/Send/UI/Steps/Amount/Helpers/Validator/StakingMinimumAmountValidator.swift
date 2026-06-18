//
//  StakingMinimumAmountValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemStaking

/// Validates the yield's enter-minimum. Used by restaking and by Cardano staking (which stakes the full
/// balance gated by that minimum); the restake case discounts the already-paid deposit.
class StakingMinimumAmountValidator {
    private let tokenItem: TokenItem
    private let action: StakingAction.ActionType
    private let stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    private var bag = Set<AnyCancellable>()

    private var minimumAmount: Decimal?

    init(
        tokenItem: TokenItem,
        action: StakingAction.ActionType,
        stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    ) {
        self.tokenItem = tokenItem
        self.stakingManagerStatePublisher = stakingManagerStatePublisher
        self.action = action
        bind()
    }

    private func bind() {
        stakingManagerStatePublisher
            .withWeakCaptureOf(self)
            .compactMap { validator, state -> Decimal? in
                if case .availableToStake(let yieldInfo) = state {
                    return yieldInfo.enterMinimumRequirement
                }

                // Reduce the minimum when staking more, because the deposit is already paid.
                if case .staked(let staked) = state,
                   case .pending(.stake) = validator.action {
                    let stakingParams = StakingBlockchainParams(blockchain: validator.tokenItem.blockchain)
                    return staked.yieldInfo.enterMinimumRequirement - Decimal(stakingParams.stakingDeposit)
                }

                return nil
            }
            .sink(receiveValue: { [weak self] amount in
                self?.minimumAmount = amount
            })
            .store(in: &bag)
    }
}

extension StakingMinimumAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        if let minAmount = minimumAmount, amount < minAmount {
            throw StakingValidationError.minAmountRequirementError(minAmount, action: action)
        }
    }
}
