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
        let externalTxId: String
        let providerName: String
        let txUrl: String?
    }
}

extension RatingModel.Transaction {
    init?(from transaction: PendingTransaction) {
        guard case .swap = transaction.type else { return nil }
        guard transaction.transactionStatus.canBeUsedAsRecent else { return nil }
        guard let externalTxId = transaction.externalTxId else { return nil }

        self.externalTxId = externalTxId
        providerName = transaction.provider.name
        txUrl = transaction.externalTxURL
    }
}
