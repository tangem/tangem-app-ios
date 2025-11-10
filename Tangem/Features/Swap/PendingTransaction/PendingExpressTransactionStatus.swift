//
//  PendingExpressTransactionStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemExpress

enum PendingExpressTransactionStatus: String, Equatable, Codable {
    case created
    case awaitingDeposit
    case awaitingHash
    case confirming
    case buying
    case exchanging
    case sendingToUser
    case finished
    case failed
    case unknown
    case refunded
    case refunding
    case verificationRequired
    case expired
    case paused
    case txFailed

    var pendingStatusTitle: String {
        switch self {
        case .created, .awaitingDeposit: Localization.expressExchangeStatusReceiving
        case .awaitingHash: Localization.expressExchangeStatusWaitingTxHash
        case .confirming: Localization.expressExchangeStatusConfirming
        case .exchanging: Localization.expressExchangeStatusExchanging
        case .buying: Localization.expressExchangeStatusBuying
        case .sendingToUser: Localization.expressExchangeStatusSending
        case .finished: Localization.commonDone
        case .failed, .unknown, .txFailed: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .refunding: Localization.expressExchangeStatusRefunding
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .expired: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    var activeStatusTitle: String {
        switch self {
        case .created, .awaitingDeposit: Localization.expressExchangeStatusReceivingActive
        case .awaitingHash: Localization.expressExchangeStatusWaitingTxHash
        case .confirming: Localization.expressExchangeStatusConfirmingActive
        case .exchanging: Localization.expressExchangeStatusExchangingActive
        case .buying: Localization.expressExchangeStatusBuyingActive
        case .sendingToUser: Localization.expressExchangeStatusSendingActive
        case .finished: Localization.commonDone
        case .failed, .unknown, .txFailed: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .refunding: Localization.expressExchangeStatusRefunding
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .expired: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    var passedStatusTitle: String {
        switch self {
        case .created, .awaitingDeposit: Localization.expressExchangeStatusReceived
        case .awaitingHash: Localization.expressExchangeStatusWaitingTxHash
        case .confirming: Localization.expressExchangeStatusConfirmed
        case .exchanging: Localization.expressExchangeStatusExchanged
        case .buying: Localization.expressExchangeStatusBought
        case .sendingToUser: Localization.expressExchangeStatusSent
        case .finished: Localization.commonDone
        case .failed, .unknown, .txFailed: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .refunding: Localization.expressExchangeStatusRefunding
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .expired: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    func isTerminated(branch: ExpressBranch) -> Bool {
        switch self {
        case .finished,
             .refunded,
             .expired,
             .txFailed where branch == .swap,
             .failed where branch == .onramp:
            return true
        case .created,
             .awaitingDeposit,
             .confirming,
             .exchanging,
             .buying,
             .sendingToUser,
             .failed,
             .verificationRequired,
             .awaitingHash,
             .unknown,
             .paused,
             .txFailed,
             .refunding:
            return false
        }
    }

    var isDone: Bool {
        self == .finished
    }

    var canBeUsedAsRecent: Bool {
        [.finished, .failed, .refunded].contains(self)
    }

    /// Required for verification the ability to hide the transaction status bottom sheet
    var isCanBeHideAutomatically: Bool {
        switch self {
        case .finished:
            true
        case .created,
             .awaitingDeposit,
             .confirming,
             .exchanging,
             .buying,
             .sendingToUser,
             .failed,
             .txFailed,
             .verificationRequired,
             .awaitingHash,
             .unknown,
             .paused,
             .refunded,
             .expired,
             .refunding:
            false
        }
    }

    var isProcessingExchange: Bool {
        switch self {
        case .created,
             .awaitingDeposit,
             .confirming,
             .exchanging,
             .buying,
             .sendingToUser:
            return true
        case .finished,
             .failed,
             .txFailed,
             .verificationRequired,
             .awaitingHash,
             .unknown,
             .paused,
             .refunding,
             .refunded,
             .expired:
            return false
        }
    }
}
