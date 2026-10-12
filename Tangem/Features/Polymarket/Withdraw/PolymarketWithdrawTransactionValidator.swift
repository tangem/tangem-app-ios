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
    let minimum: PolymarketUSDAmount

    func validate(amount: Amount) throws {
        guard let balance = availableBalanceProvider.balanceType.value else {
            throw ValidationError.balanceNotFound
        }

        guard amount.value <= balance else {
            throw ValidationError.amountExceedsBalance
        }

        if let minimumAmount = minimum.inToken(), amount.value < minimumAmount {
            throw ValidationError.minimumRestrictAmount(amount: Amount(with: amount, value: minimumAmount))
        }
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validate(amount: amount)
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try validate(amount: amount)
    }
}
