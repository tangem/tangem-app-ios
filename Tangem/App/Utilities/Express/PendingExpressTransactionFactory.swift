//
//  PendingExpressTransactionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct PendingExpressTransactionFactory {
    private let defaultStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .exchanging, .sendingToUser]
    private let failedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .failed, .refunded]
    private let txFailedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .txFailed, .refunded]
    private let verifyingStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]
    private let canceledStatusesList: [PendingExpressTransactionStatus] = [.canceled]
    private let awaitingHashStatusesList: [PendingExpressTransactionStatus] = [.awaitingHash]
    private let unknownHashStatusesList: [PendingExpressTransactionStatus] = [.unknown]
    private let pausedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .paused]

    func buildPendingExpressTransaction(
        with params: PendingExpressTransactionParams,
        refundedTokenItem: TokenItem?,
        for transactionRecord: ExpressPendingTransactionRecord
    ) -> PendingExpressTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord
        switch params.externalStatus {
        case .created, .waiting:
            currentStatus = .awaitingDeposit
        case .confirming:
            currentStatus = .confirming
        case .exchanging:
            currentStatus = .exchanging
        case .sending:
            currentStatus = .sendingToUser
        case .finished:
            currentStatus = .done
        case .waitingTxHash:
            currentStatus = .awaitingHash
            statusesList = awaitingHashStatusesList
        case .unknown:
            currentStatus = .unknown
            statusesList = unknownHashStatusesList
        case .failed, .exchangeTxSent:
            currentStatus = .failed
            statusesList = failedStatusesList
        case .txFailed:
            currentStatus = .txFailed
            statusesList = txFailedStatusesList
        case .refunded:
            currentStatus = .refunded
            statusesList = failedStatusesList
        case .verifying:
            currentStatus = .verificationRequired
            statusesList = verifyingStatusesList
        case .expired:
            currentStatus = .canceled
            statusesList = canceledStatusesList
        case .paused:
            currentStatus = .paused
            statusesList = pausedStatusesList
        }

        transactionRecord.transactionStatus = currentStatus
        transactionRecord.refundedTokenItem = refundedTokenItem

        transactionRecord.averageDuration = params.averageDuration
        transactionRecord.createdAt = params.createdAt

        return .init(transactionRecord: transactionRecord, statuses: statusesList)
    }

    func buildPendingExpressTransaction(for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        let statusesList: [PendingExpressTransactionStatus] = {
            switch transactionRecord.transactionStatus {
            case .created, .awaitingDeposit, .confirming, .exchanging, .buying, .sendingToUser, .done:
                return defaultStatusesList
            case .canceled:
                return canceledStatusesList
            case .failed, .refunded:
                return failedStatusesList
            case .txFailed:
                return txFailedStatusesList
            case .paused:
                return pausedStatusesList
            case .awaitingHash:
                return awaitingHashStatusesList
            case .unknown:
                return unknownHashStatusesList
            case .verificationRequired:
                return verifyingStatusesList
            }
        }()

        return .init(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }
}
