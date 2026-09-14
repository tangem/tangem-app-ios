//
//  PolymarketWithdrawTransactionValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation

struct PolymarketWithdrawTransactionValidator: SendTransactionValidator {
    let availableBalanceProvider: any TokenBalanceProvider

    func validate(amount: Amount) throws {
        guard let balance = availableBalanceProvider.balanceType.value else {
            throw ValidationError.balanceNotFound
        }

        guard amount.value <= balance else {
            throw ValidationError.amountExceedsBalance
        }

        // Polymarket documents no withdrawal minimum, yet its quote endpoint refuses amounts under
        // roughly 0.1 pUSD, so the floor stays conservative until the delivered one is confirmed.
        // [REDACTED_TODO_COMMENT]
        guard amount.value >= Constants.minimumAmount else {
            throw ValidationError.minimumRestrictAmount(
                amount: Amount(with: amount, value: Constants.minimumAmount)
            )
        }
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validate(amount: amount)
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try validate(amount: amount)
    }
}

// MARK: - Constants

private extension PolymarketWithdrawTransactionValidator {
    enum Constants {
        static let minimumAmount: Decimal = 1
    }
}
