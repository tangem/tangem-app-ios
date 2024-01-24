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

public extension Wallet {
    func canSend(amountType: Amount.AmountType) -> Bool {
        if hasPendingTransactions {
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

        return hasFeeCurrency(amountType: amountType)
    }

    func hasFeeCurrency(amountType: Amount.AmountType) -> Bool {
        let feeAmountType = feeAmountType(transactionAmountType: amountType)
        let feeAmount = amounts[feeAmountType]?.value ?? 0

        return feeAmount > 0
    }

    private var hasPendingTransactions: Bool {
        // For bitcoin we check only outgoing transaction
        // because we will not use unconfirmed utxo
        if case .bitcoin = blockchain {
            return pendingTransactions.contains { !$0.isIncoming }
        }

        return hasPendingTx
    }

    private func feeAmountType(transactionAmountType: Amount.AmountType) -> Amount.AmountType {
        switch blockchain.feePaidCurrency {
        case .coin:
            return .coin
        case .token(let value):
            return .token(value: value)
        case .sameCurrency:
            return transactionAmountType
        }
    }
}
