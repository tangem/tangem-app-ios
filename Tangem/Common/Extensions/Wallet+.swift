//
//  Wallet+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

extension Wallet {

    public func canSend(amountType: Amount.AmountType) -> Bool {
        if hasPendingTx {
            return false
        }

        if amounts.isEmpty { // not loaded from blockchain
            return false
        }

        if amounts.values.first(where: { $0.value > 0 }) == nil { // empty wallet
            return false
        }

        let amount = amounts[amountType]?.value ?? 0
        if amount <= 0 {
            return false
        }

        let coinAmount = amounts[.coin]?.value ?? 0
        if coinAmount <= 0 { // not enough fee
            return false
        }

        return true
    }
}
