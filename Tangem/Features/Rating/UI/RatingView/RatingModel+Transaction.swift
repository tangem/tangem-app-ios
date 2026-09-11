//
//  RatingModel+Transaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

extension RatingModel {
    struct Transaction {
        let transactionId: String
        let providerName: String
        let txUrl: String?
    }
}

extension RatingModel.Transaction {
    init?(from transaction: PendingTransaction) {
        guard case .swap = transaction.type, Self.isRateable(transaction.transactionStatus) else { return nil }

        transactionId = transaction.expressTransactionId
        providerName = transaction.provider.name
        txUrl = transaction.externalTxURL
    }

    static func isRateable(_ status: ExpressTransactionStatus) -> Bool {
        switch status {
        case .finished, .refunded, .expired, .txFailed:
            true
        case .unknown,
             .preview,
             .created,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .confirming,
             .exchanging,
             .sending,
             .failed,
             .verifying,
             .paused:
            false
        }
    }

    static func isRateable(_ status: PendingExpressTransactionStatus) -> Bool {
        switch status {
        case .finished, .refunded, .expired, .txFailed:
            true
        case .created,
             .awaitingDeposit,
             .awaitingHash,
             .confirming,
             .buying,
             .exchanging,
             .sendingToUser,
             .failed,
             .unknown,
             .refunding,
             .verificationRequired,
             .paused:
            false
        }
    }
}
