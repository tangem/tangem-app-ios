
//
//  RestakingAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemStaking

class RestakingAmountValidator {
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
                // this validator is also used for regular staking flow in cardano
                if case .availableToStake(let yieldInfo) = state {
                    return yieldInfo.enterMinimumRequirement
                }

                // reduce minimum amount when user is restaking
                // because deposit is already paid
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

extension RestakingAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        if let minAmount = minimumAmount, amount < minAmount {
            throw StakingValidationError.amountRequirementError(
                minAmount: minAmount,
                action: action
            )
        }
    }
}
