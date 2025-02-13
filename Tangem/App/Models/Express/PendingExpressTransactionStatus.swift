//
//  PendingExpressTransactionStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

enum PendingExpressTransactionStatus: String, Equatable, Codable {
    case created
    case awaitingDeposit
    case awaitingHash
    case confirming
    case buying
    case exchanging
    case sendingToUser
    case done
    case failed
    case unknown
    case refunded
    case verificationRequired
    case canceled
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
        case .done: Localization.commonDone
        case .failed, .unknown, .txFailed: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .canceled: Localization.expressExchangeStatusCanceled
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
        case .done: Localization.commonDone
        case .failed, .unknown, .txFailed: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .canceled: Localization.expressExchangeStatusCanceled
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
        case .done: Localization.commonDone
        case .failed, .unknown, .txFailed: Localization.expressExchangeStatusFailed
        case .refunded: Localization.expressExchangeStatusRefunded
        case .verificationRequired: Localization.expressExchangeStatusVerifying
        case .canceled: Localization.expressExchangeStatusCanceled
        case .paused: Localization.expressExchangeStatusPaused
        }
    }

    func isTerminated(branch: ExpressBranch) -> Bool {
        switch self {
        case .done,
             .refunded,
             .canceled,
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
             .txFailed:
            return false
        }
    }

    var isDone: Bool {
        self == .done
    }

    // Required for verification the ability to hide the transaction status bottom sheet
    func isCanBeHideAutomatically(branch: ExpressBranch) -> Bool {
        switch self {
        case .done, .failed, .txFailed:
            true
        case .created,
             .awaitingDeposit,
             .confirming,
             .exchanging,
             .buying,
             .sendingToUser,
             .failed where branch == .onramp,
             .txFailed where branch == .swap,
             .verificationRequired,
             .awaitingHash,
             .unknown,
             .paused,
             .refunded,
             .canceled:
            false
        }
    }
}
