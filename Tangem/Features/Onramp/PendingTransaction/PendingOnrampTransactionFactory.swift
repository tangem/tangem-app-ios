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

    static func pendingStatus(from onrampStatus: OnrampTransactionStatus) -> PendingExpressTransactionStatus {
        switch onrampStatus {
        case .created: return .created
        case .waitingForPayment: return .awaitingDeposit
        case .paymentProcessing: return .confirming
        case .sending, .paid: return .buying
        case .finished: return .finished
        case .failed: return .failed
        case .refunding: return .refunding
        case .refunded: return .refunded
        case .verifying: return .verificationRequired
        case .expired: return .expired
        case .paused: return .paused
        case .unknown: return .unknown
        }
    }

    func buildPendingOnrampTransaction(
        currentOnrampTransaction: OnrampTransaction,
        for transactionRecord: OnrampPendingTransactionRecord
    ) -> PendingOnrampTransaction {
        let currentStatus: PendingExpressTransactionStatus = Self.pendingStatus(from: currentOnrampTransaction.status)
        var statusesList: [PendingExpressTransactionStatus] = defaultStatusesList
        var transactionRecord = transactionRecord

        switch currentOnrampTransaction.status {
        case .failed:
            statusesList = failedStatusesList
        case .refunding:
            statusesList = refundingStatusesList
        case .refunded:
            statusesList = refundedStatusesList
        case .verifying:
            statusesList = verifyingStatusesList
        case .expired:
            statusesList = canceledStatusesList
        case .paused:
            statusesList = pausedStatusesList
        case .unknown:
            statusesList = unknownHashStatusesList
        case .created, .waitingForPayment, .paymentProcessing, .sending, .paid, .finished:
            break
        }

        transactionRecord.transactionStatus = currentStatus
        transactionRecord.destinationTokenTxInfo = .init(
            userWalletId: transactionRecord.destinationTokenTxInfo.userWalletId,
            tokenItem: transactionRecord.destinationTokenTxInfo.tokenItem,
            address: transactionRecord.destinationTokenTxInfo.address,
            amountString: currentOnrampTransaction.to.amount.map(\.stringValue) ?? "",
            isCustom: transactionRecord.destinationTokenTxInfo.isCustom
        )
        transactionRecord.externalTxId = currentOnrampTransaction.externalTx?.id
        transactionRecord.externalTxURL = currentOnrampTransaction.externalTx?.url?.absoluteString

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
