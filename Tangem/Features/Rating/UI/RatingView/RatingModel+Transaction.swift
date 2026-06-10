//
//  RatingModel+Transaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension RatingModel {
    struct Transaction {
        let transactionId: String
        let providerName: String
        let txUrl: String?
    }
}

extension RatingModel.Transaction {
    init?(from transaction: PendingTransaction) {
        guard case .swap = transaction.type else { return nil }

        // Prefer externalTxId when available; otherwise fall back to expressTransactionId (e.g., DEX swaps)
        transactionId = transaction.externalTxId ?? transaction.expressTransactionId
        providerName = transaction.provider.name
        txUrl = transaction.externalTxURL
    }
}
