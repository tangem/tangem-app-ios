//
//  PolymarketFastTradingFailure.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket
import TangemUIUtils

enum PolymarketFastTradingFailure: Equatable {
    case staleSignature
    case busy
    case limitReached
    case notReady
    case generic

    init?(error: Error) {
        switch error {
        case PolymarketSigningError.cancelled, PolymarketSessionKeyError.cancelled:
            return nil
        case let error where error.isCancellationError:
            return nil
        case PolymarketSessionKeyError.refused(_, let reason, let detail):
            self.init(reason: reason, detail: detail)
        case PolymarketSessionKeyManagerError.operationInProgress:
            self = .busy
        case PolymarketAccountFundsError.depositWalletNotReadyToTrade:
            self = .notReady
        default:
            self = .generic
        }
    }

    private init(reason: PolymarketSessionKeyError.Reason, detail: String?) {
        switch reason {
        case .busy, .deviceHasSessionKey:
            self = .busy
        case .relayerRejected where detail?.localizedCaseInsensitiveContains(Constants.relayerInFlightMarker) == true:
            self = .busy
        case .invalidDeadline, .invalidValidUntil, .invalidSignature, .nonceAlreadyUsed, .relayerRejected:
            self = .staleSignature
        case .limitReached:
            self = .limitReached
        case .walletNotReady, .walletNotOwned:
            self = .notReady
        case .malformedRequest, .invalidWalletId, .invalidCall, .ownedByAnotherWallet, .invalidReplacement,
             .notToggleable, .notFound, .unknown:
            self = .generic
        }
    }

    var message: String {
        switch self {
        case .staleSignature: PolymarketFastTradingStrings.staleSignature
        case .busy: PolymarketFastTradingStrings.deviceBusy
        case .limitReached: PolymarketFastTradingStrings.limitReached
        case .notReady: PolymarketFastTradingStrings.notReady
        case .generic: Localization.commonUnknownError
        }
    }

    var alert: AlertBinder {
        AlertBinder(title: PolymarketFastTradingStrings.title, message: message)
    }
}

// MARK: - Constants

private extension PolymarketFastTradingFailure {
    enum Constants {
        static let relayerInFlightMarker = "in-flight"
    }
}
