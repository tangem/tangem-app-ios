//
//  CommonPendingExpressTransactionAnalyticsTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class CommonPendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker {
    typealias PendingTransactionId = String

    private let mapper = PendingExpressTransactionAnalyticsStatusMapper()
    private var trackedStatuses: ThreadSafeContainer<[PendingTransactionId: Set<Analytics.ParameterValue>]> = .init([:])

    func trackStatusForTransaction(with transactionId: PendingTransactionId, tokenSymbol: String, status: PendingExpressTransactionStatus) {
        let statusToTrack = mapper.mapToAnalyticsStatus(pendingTxStatus: status)
        var trackedStatusesSet = trackedStatuses[transactionId] ?? []
        if trackedStatusesSet.contains(statusToTrack) {
            return
        }

        Analytics.log(event: .tokenSwapStatus, params: [
            .token: tokenSymbol,
            .status: statusToTrack.rawValue,
        ])
        trackedStatusesSet.insert(statusToTrack)
        trackedStatuses.mutate { $0[transactionId] = trackedStatusesSet }
    }
}

extension CommonPendingExpressTransactionAnalyticsTracker {
    struct PendingExpressTransactionAnalyticsStatusMapper {
        func mapToAnalyticsStatus(pendingTxStatus: PendingExpressTransactionStatus) -> Analytics.ParameterValue {
            switch pendingTxStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser:
                return .inProgress
            case .done:
                return .done
            case .failed:
                return .fail
            case .refunded:
                return .refunded
            case .verificationRequired:
                return .kyc
            case .canceled:
                return .canceled
            }
        }
    }
}
