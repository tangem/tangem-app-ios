//
//  MinimumBalanceRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MinimumBalanceRestrictable {
    var minimumBalance: Amount { get }
    func validateMinimumBalance(amount: Amount, fee: Amount) throws
}

extension MinimumBalanceRestrictable where Self: WalletProvider {
    func validateMinimumBalance(amount: Amount, fee: Amount) throws {
        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        let total = amount + fee
        let remainderBalance = balance - total
        if remainderBalance < minimumBalance {
            throw ValidationError.minimumBalance(minimumBalance: minimumBalance, canLeaveAmount: balance.value > minimumBalance.value)
        }
    }
}
