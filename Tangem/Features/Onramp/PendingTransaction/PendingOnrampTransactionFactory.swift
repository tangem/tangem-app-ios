//
//  PendingOnrampTransactionFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct PendingOnrampTransactionFactory {
    private let defaultStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .buying, .sendingToUser]
    private let failedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .failed, .buying, .sendingToUser]
    private let refundingStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .refunding, .buying, .sendingToUser]
    private let refundedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .refunded, .buying, .sendingToUser]
    private let verifyingStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .verificationRequired, .sendingToUser]
    private let canceledStatusesList: [PendingExpressTransactionStatus] = [.expired]
    private let awaitingHashStatusesList: [PendingExpressTransactionStatus] = [.awaitingHash]
    private let unknownHashStatusesList: [PendingExpressTransactionStatus] = [.unknown]
    private let pausedStatusesList: [PendingExpressTransactionStatus] = [.awaitingDeposit, .confirming, .paused]

    func buildPendingOnrampTransaction(
        currentOnrampTransaction: OnrampTransaction,
        for transactionRecord: OnrampPendingTransactionRecord
    ) -> PendingOnrampTransaction {
        let currentStatus: PendingExpressTransactionStatus
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord

        switch currentOnrampTransaction.status {
        case .created:
            currentStatus = .created
        case .waitingForPayment:
            currentStatus = .awaitingDeposit
        case .paymentProcessing:
            currentStatus = .confirming
        case .sending, .paid:
            currentStatus = .buying
        case .finished:
            currentStatus = .finished
        case .failed:
            currentStatus = .failed
            statusesList = failedStatusesList
        case .refunding:
            currentStatus = .refunding
            statusesList = refundingStatusesList
        case .refunded:
            currentStatus = .refunded
            statusesList = refundedStatusesList
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
        transactionRecord.destinationTokenTxInfo = .init(
            userWalletId: transactionRecord.destinationTokenTxInfo.userWalletId,
            tokenItem: transactionRecord.destinationTokenTxInfo.tokenItem,
            address: transactionRecord.destinationTokenTxInfo.address,
            amountString: currentOnrampTransaction.toAmount.map(\.stringValue) ?? "",
            isCustom: transactionRecord.destinationTokenTxInfo.isCustom
        )
        transactionRecord.externalTxId = currentOnrampTransaction.externalTxId
        transactionRecord.externalTxURL = currentOnrampTransaction.externalTxURL

        return PendingOnrampTransaction(
            transactionRecord: transactionRecord,
            statuses: statusesList
        )
    }

    func buildPendingOnrampTransaction(for transactionRecord: OnrampPendingTransactionRecord) -> PendingOnrampTransaction {
        let statusesList: [PendingExpressTransactionStatus] = {
            switch transactionRecord.transactionStatus {
            case .created, .awaitingDeposit, .confirming, .exchanging, .buying, .sendingToUser, .finished:
                return defaultStatusesList
            case .expired:
                return canceledStatusesList
            case .failed, .txFailed:
                return failedStatusesList
            case .refunding, .refunded:
                return refundedStatusesList
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

        return .init(transactionRecord: transactionRecord, statuses: statusesList)
    }
}
