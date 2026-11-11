//
//  PendingTransactionsBlockingPolicy.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct PendingTransactionsBlockingPolicy {
    func hasBlockingTransactions(
        in pendingTransactions: [PendingTransactionRecord],
        blockchain: Blockchain,
        amountType: Amount.AmountType?
    ) -> Bool {
        // For bitcoin we check only outgoing transaction
        // because we will not use unconfirmed utxo
        if case .bitcoin = blockchain {
            return pendingTransactions.contains { !$0.isIncoming }
        }

        guard !blockchain.isParallelTransactionAllowed else {
            return false
        }

        guard let amountType else {
            return pendingTransactions.isNotEmpty
        }

        return pendingTransactions.contains { $0.amount.type == amountType }
    }
}
