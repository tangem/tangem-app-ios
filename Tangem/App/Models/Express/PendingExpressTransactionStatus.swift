//
//  PendingExpressTransactionStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum PendingExpressTransactionStatus: String, Equatable {
    case awaitingDeposit
    case confirming
    case exchanging
    case sendingToUser
    case done
    case failed
    case refunded
    case verificationRequired

    var pendingStatusTitle: String {
        switch self {
        case .awaitingDeposit: return Localization.expressExchangeStatusReceiving
        case .confirming: return Localization.expressExchangeStatusConfirming
        case .exchanging: return Localization.expressExchangeStatusExchanging
        case .sendingToUser: return Localization.expressExchangeStatusSending
        case .done: return Localization.commonDone
        case .failed: return Localization.expressExchangeStatusFailed
        case .refunded: return Localization.expressExchangeStatusRefunded
        case .verificationRequired: return Localization.expressExchangeStatusVerifying
        }
    }

    var activeStatusTitle: String {
        switch self {
        case .awaitingDeposit: return Localization.expressExchangeStatusReceivingActive
        case .confirming: return Localization.expressExchangeStatusConfirmingActive
        case .exchanging: return Localization.expressExchangeStatusExchangingActive
        case .sendingToUser: return Localization.expressExchangeStatusSendingActive
        case .done: return Localization.commonDone
        case .failed: return Localization.expressExchangeStatusFailed
        case .refunded: return Localization.expressExchangeStatusRefundedActive
        case .verificationRequired: return Localization.expressExchangeStatusVerifying
        }
    }

    var passedStatusTitle: String {
        switch self {
        case .awaitingDeposit: return Localization.expressExchangeStatusReceived
        case .confirming: return Localization.expressExchangeStatusConfirmed
        case .exchanging: return Localization.expressExchangeStatusExchanged
        case .sendingToUser: return Localization.expressExchangeStatusSent
        case .done: return Localization.commonDone
        case .failed: return Localization.expressExchangeStatusFailed
        case .refunded: return Localization.expressExchangeStatusRefunded
        case .verificationRequired: return Localization.expressExchangeStatusVerified
        }
    }

    var isTransactionInProgress: Bool {
        switch self {
        case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .failed, .verificationRequired:
            return true
        case .done, .refunded:
            return false
        }
    }
}
