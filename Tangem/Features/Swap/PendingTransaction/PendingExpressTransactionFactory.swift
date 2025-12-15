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
    private let canceledStatusesList: [PendingExpressTransactionStatus] = [.expired]
    private let awaitingHashStatusesList: [PendingExpressTransactionStatus] = [.awaitingHash]
    private let unknownHashStatusesList: [PendingExpressTransactionStatus] = [.unknown]
    private let pausedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .paused]

    func buildPendingExpressTransaction(
        expressTransaction: ExpressTransaction,
        refundedTokenItem: TokenItem?,
        for transactionRecord: ExpressPendingTransactionRecord
    ) -> PendingExpressTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord
        switch expressTransaction.externalStatus {
        case .created, .waiting, .exchangeTxSent:
            currentStatus = .awaitingDeposit
        case .confirming:
            currentStatus = .confirming
        case .exchanging:
            currentStatus = .exchanging
        case .sending:
            currentStatus = .sendingToUser
        case .finished:
            currentStatus = .finished
        case .waitingTxHash:
            currentStatus = .awaitingHash
            statusesList = awaitingHashStatusesList
        case .unknown:
            currentStatus = .unknown
            statusesList = unknownHashStatusesList
        case .failed:
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
            currentStatus = .expired
            statusesList = canceledStatusesList
        case .paused:
            currentStatus = .paused
            statusesList = pausedStatusesList
        }

        transactionRecord.transactionStatus = currentStatus
        transactionRecord.refundedTokenItem = refundedTokenItem

        transactionRecord.externalTxId = expressTransaction.externalTxId
        transactionRecord.externalTxURL = expressTransaction.externalTxUrl

        transactionRecord.averageDuration = expressTransaction.averageDuration
        transactionRecord.createdAt = expressTransaction.createdAt

        return .init(transactionRecord: transactionRecord, statuses: statusesList)
    }

    func buildPendingExpressTransaction(for transactionRecord: ExpressPendingTransactionRecord) -> PendingExpressTransaction {
        let statusesList: [PendingExpressTransactionStatus] = {
            switch transactionRecord.transactionStatus {
            case .created, .awaitingDeposit, .confirming, .exchanging, .buying, .sendingToUser, .finished:
                return defaultStatusesList
            case .expired:
                return canceledStatusesList
            case .failed, .refunded, .refunding:
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
