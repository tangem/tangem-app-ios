//
//  RentExtemptionRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol RentExtemptionRestrictable {
    var minimalAmountForRentExemption: Amount { get }

    func validateRentExemption(amount: Amount, fee: Amount) throws
    func validateDestinationForRentExemption(amount: Amount, fee: Fee, destination: DestinationType) async throws
}

extension RentExtemptionRestrictable where Self: WalletProvider {
    func validateRentExemption(amount: Amount, fee: Amount) throws {
        guard let balance = wallet.amounts[.coin] else {
            throw ValidationError.balanceNotFound
        }

        var remainingBalance = balance.value

        if amount.type == balance.type {
            remainingBalance -= amount.value
        }

        if fee.type == balance.type {
            remainingBalance -= fee.value
        }

        guard remainingBalance >= 0 else {
            throw ValidationError.totalExceedsBalance
        }

        if remainingBalance > 0, remainingBalance < minimalAmountForRentExemption.value {
            throw ValidationError.remainingAmountIsLessThanRentExemption(amount: minimalAmountForRentExemption)
        }
    }
}
