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
    private let failedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .failed, .refunded]
    private let verifyingStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]

    func buildPendingExpressTransaction(currentExpressStatus: ExpressTransactionStatus, for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord
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
            statusesList = failedStatusesList
        case .refunded:
            currentStatus = .refunded
            statusesList = failedStatusesList
        case .verifying:
            currentStatus = .verificationRequired
            statusesList = verifyingStatusesList
        }

        transactionRecord.transactionStatus = currentStatus
        return .init(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }

    func buildPendingExpressTransaction(for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        var statusesList = defaultStatusesList
        switch transactionRecord.transactionStatus {
        case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done, .expired:
            break
        case .failed, .refunded:
            statusesList = failedStatusesList
        case .verificationRequired:
            statusesList = verifyingStatusesList
        }

        return .init(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }
}
