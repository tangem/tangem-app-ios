//
//  PolymarketFastTradingFailure.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemNetworkUtils
import TangemPolymarket
import TangemUIUtils

enum PolymarketFastTradingFailure: Equatable {
    case staleSignature
    case busy
    case limitReached
    case notReady
    case notEnabled
    case generic

    init?(error: Error) {
        switch error {
        case PolymarketSigningError.cancelled, PolymarketSessionKeyError.cancelled:
            return nil
        case let error where error.isCancellationError:
            return nil
        case PolymarketSessionKeyManagerError.unsettled:
            return nil
        case let error as PolymarketSessionKeyError where error.isBusyRefusal:
            self = .busy
        case PolymarketSessionKeyError.refused(_, let reason, _):
            self.init(reason: reason)
        case PolymarketSessionKeyManagerError.operationInProgress:
            self = .busy
        case PolymarketSessionKeyManagerError.nonceSpentElsewhere:
            self = .staleSignature
        case PolymarketAccountFundsError.depositWalletNotReadyToTrade:
            self = .notReady
        default:
            self = .generic
        }
    }

    private init(reason: PolymarketSessionKeyError.Reason) {
        switch reason {
        case .busy, .deviceHasSessionKey:
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
        case .staleSignature:
            PolymarketFastTradingStrings.staleSignature
        case .busy:
            PolymarketFastTradingStrings.deviceBusy
        case .limitReached:
            PolymarketFastTradingStrings.limitReached
        case .notReady:
            PolymarketFastTradingStrings.notReady
        case .notEnabled:
            PolymarketFastTradingStrings.notEnabledAfterOnboarding
        case .generic:
            Localization.commonUnknownError
        }
    }

    var alert: AlertBinder {
        AlertBinder(title: PolymarketFastTradingStrings.title, message: message)
    }
}

// MARK: - Logging

extension PolymarketFastTradingFailure {
    static func logDescription(of error: Error) -> String {
        switch error {
        case PolymarketSessionKeyError.refused(let statusCode, let reason, _):
            "refused with \(statusCode), \(reason)"
        case PolymarketSessionKeyError.other(let apiError), let apiError as PolymarketAPIError:
            apiLogDescription(of: apiError)
        case let error as URLError:
            "connection error \(error.code.rawValue)"
        default:
            "\(error)"
        }
    }

    private static func apiLogDescription(of apiError: PolymarketAPIError) -> String {
        switch apiError {
        case .http(let statusCode, _):
            "HTTP \(statusCode)"
        case .connection(let underlying):
            "connection error \(underlying.networkErrorCode?.rawValue ?? (underlying as NSError).code)"
        case .decoding(let field, _):
            "unreadable \(field)"
        }
    }
}
