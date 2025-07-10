//
//  MinimumAmountRestrictable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MinimumAmountRestrictable {
    var minimumRestrictAmount: Amount { get }

    func validateMinimumRestrictAmount(amount: Amount, fee: Amount) throws
}

extension MinimumAmountRestrictable where Self: WalletProvider {
    func validateMinimumRestrictAmount(amount: Amount, fee: Amount) throws {
        if amount < minimumRestrictAmount {
            throw ValidationError.minimumRestrictAmount(amount: minimumRestrictAmount)
        }
    }
}
