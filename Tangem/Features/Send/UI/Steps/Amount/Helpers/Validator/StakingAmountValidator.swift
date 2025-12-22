//
//  StakingAmountValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import Combine
import TangemStaking

class StakingAmountValidator {
    private let tokenItem: TokenItem
    private let validator: TransactionValidator
    private var minimumAmount: Decimal?
    private var maximumAmount: Decimal?
    private let stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    private let balanceFormatter = BalanceFormatter()
    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        validator: TransactionValidator,
        stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    ) {
        self.tokenItem = tokenItem
        self.validator = validator
        self.stakingManagerStatePublisher = stakingManagerStatePublisher
        bind()
    }

    private func bind() {
        let yieldPublisher = stakingManagerStatePublisher
            .compactMap { state -> StakingYieldInfo? in
                switch state {
                case .availableToStake(let yieldInfo):
                    return yieldInfo
                case .staked(let staked):
                    return staked.yieldInfo
                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()

        yieldPublisher
            .map { $0.enterMinimumRequirement }
            .sink(receiveValue: { [weak self] amount in
                self?.minimumAmount = amount
            })
            .store(in: &bag)

        yieldPublisher
            .sink(receiveValue: { [weak self] yieldInfo in
                self?.maximumAmount = yieldInfo.maximumStakeAmount
            })
            .store(in: &bag)
    }
}

extension StakingAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        if let minimumAmount, amount < minimumAmount {
            throw StakingValidationError.minAmountRequirementError(minimumAmount, action: .stake)
        }

        if let maximumAmount, amount > maximumAmount {
            throw StakingValidationError.maxAmountRequirementError(
                balanceFormatter.formatCryptoBalance(
                    maximumAmount,
                    currencyCode: tokenItem.currencySymbol
                )
            )
        }

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        try validator.validate(amount: amount)
    }
}

enum StakingValidationError: LocalizedError {
    case minAmountRequirementError(_ minAmount: Decimal, action: StakingAction.ActionType)
    case maxAmountRequirementError(_ maxAmountFormatted: String)

    var errorDescription: String? {
        switch self {
        case .minAmountRequirementError(let minAmount, _):
            Localization.stakingAmountRequirementError(minAmount)
        case .maxAmountRequirementError(let maxAmountFormatted):
            Localization.stakingMaxAmountRequirementError(maxAmountFormatted)
        }
    }
}
