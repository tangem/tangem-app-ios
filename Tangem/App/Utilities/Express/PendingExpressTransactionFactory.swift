//
//  PendingExpressTransactionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct PendingExpressTransactionFactory {
    private let defaultStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .exchanging, .sendingToUser]

    func buildPendingExpressTransaction(currentExpressStatus: ExpressTransactionStatus, for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        switch currentExpressStatus {
        case .new, .waiting:
            currentStatus = .awaitingDeposit
        case .confirming:
            currentStatus = .confirming
        case .exchanging:
            currentStatus = .exchanging
        case .sending:
            currentStatus = .sendingToUser
        case .finished:
            currentStatus = .done
        case .failed:
            currentStatus = .failed
            statusesList = [.awaitingDeposit, .confirming, .failed, .refunded]
        case .refunded:
            currentStatus = .refunded
            statusesList = [.awaitingDeposit, .confirming, .failed, .refunded]
        case .verifying:
            currentStatus = .verificationRequired
            statusesList = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]
        }

        return .init(
            transactionRecord: transactionRecord,
            currentStatus: currentStatus,
            statuses: statusesList
        )
    }
}
