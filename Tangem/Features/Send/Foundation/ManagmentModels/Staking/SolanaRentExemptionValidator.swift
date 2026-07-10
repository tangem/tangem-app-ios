//
//  SolanaRentExemptionValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemStaking

final class SolanaRentExemptionValidator {
    private let tokenItem: TokenItem
    private let transactionValidator: SendTransactionValidator
    private let tokenFeeProvidersManager: TokenFeeProvidersManager

    init(
        tokenItem: TokenItem,
        transactionValidator: SendTransactionValidator,
        tokenFeeProvidersManager: TokenFeeProvidersManager
    ) {
        self.tokenItem = tokenItem
        self.transactionValidator = transactionValidator
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
    }
}

// MARK: - StakingPreflightValidator

extension SolanaRentExemptionValidator: StakingPreflightValidator {
    func validate() async -> StakingPreflightFailure? {
        let estimatedFee: BSDKFee
        do {
            estimatedFee = try await tokenFeeProvidersManager.estimatedFee(amount: .zero)
        } catch {
            StakingLogger.error(error: error)
            return nil
        }

        let zeroAmount = BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: .zero)

        do {
            try transactionValidator.validate(amount: zeroAmount, fee: estimatedFee)
            return nil
        } catch ValidationError.remainingAmountIsLessThanRentExemption(let minimumBalance) {
            return StakingPreflightFailure(
                validationError: .remainingAmountIsLessThanRentExemption(amount: minimumBalance),
                estimatedFee: estimatedFee.amount.value
            )
        } catch {
            // This validator intercepts only the rent exemption case; any other error will be handled further down the flow
            return nil
        }
    }
}
