//
//  CommonPendingExpressTransactionAnalyticsTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

actor CommonPendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker {
    typealias PendingTransactionId = String

    private let mapper = PendingExpressTransactionAnalyticsStatusMapper()
    private var trackedStatuses: [PendingTransactionId: Set<Analytics.ParameterValue>] = [:]

    func trackStatusForSwapTransaction(
        transactionId: String,
        tokenSymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        log(
            event: .tokenSwapStatus,
            params: [.token: tokenSymbol],
            transactionId: transactionId,
            status: status,
            provider: provider
        )
    }

    func trackStatusForOnrampTransaction(
        transactionId: String,
        tokenSymbol: String,
        currencySymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        log(
            event: .onrampOnrampStatus,
            params: [.token: tokenSymbol, .currency: currencySymbol],
            transactionId: transactionId,
            status: status,
            provider: provider
        )
    }

    private func log(
        event: Analytics.Event,
        params: [Analytics.ParameterKey: String],
        transactionId: PendingTransactionId,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) {
        let statusToTrack = mapper.mapToAnalyticsStatus(pendingTxStatus: status)

        guard trackedStatuses[transactionId, default: []].insert(statusToTrack).inserted else {
            return
        }

        var params = params
        params[.status] = statusToTrack.rawValue
        params[.provider] = provider.name

        Analytics.log(event: event, params: params)
    }
}

extension CommonPendingExpressTransactionAnalyticsTracker {
    struct PendingExpressTransactionAnalyticsStatusMapper {
        func mapToAnalyticsStatus(pendingTxStatus: PendingExpressTransactionStatus) -> Analytics.ParameterValue {
            switch pendingTxStatus {
            case .created, .awaitingDeposit, .confirming, .buying, .exchanging, .sendingToUser, .refunding:
                return .inProgress
            case .finished:
                return .done
            case .failed, .awaitingHash, .unknown, .paused, .txFailed:
                return .fail
            case .refunded:
                return .refunded
            case .verificationRequired:
                return .kyc
            case .expired:
                return .canceled
            }
        }
    }
}
