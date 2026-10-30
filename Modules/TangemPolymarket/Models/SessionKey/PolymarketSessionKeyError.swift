//
//  PolymarketSessionKeyError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketSessionKeyError: Error {
    case refused(statusCode: Int, reason: Reason, detail: String?)
    case cancelled
    case other(PolymarketAPIError)
}

public extension PolymarketSessionKeyError {
    enum Reason: Hashable, Sendable {
        case malformedRequest
        case invalidWalletId
        case invalidDeadline
        case invalidValidUntil
        case invalidCall
        case invalidSignature
        case walletNotOwned
        case walletNotReady
        case ownedByAnotherWallet
        case busy
        case deviceHasSessionKey
        case invalidReplacement
        case limitReached
        case notToggleable
        case notFound
        case relayerRejected
        case nonceAlreadyUsed
        case unknown(String?)

        public init(apiValue: String?) {
            switch apiValue {
            case "MALFORMED_REQUEST": self = .malformedRequest
            case "INVALID_WALLET_ID": self = .invalidWalletId
            case "INVALID_DEADLINE": self = .invalidDeadline
            case "INVALID_VALID_UNTIL": self = .invalidValidUntil
            case "INVALID_CALL": self = .invalidCall
            case "INVALID_SIGNATURE": self = .invalidSignature
            case "WALLET_NOT_OWNED": self = .walletNotOwned
            case "WALLET_NOT_READY": self = .walletNotReady
            case "SESSION_KEY_OWNED_BY_ANOTHER_WALLET": self = .ownedByAnotherWallet
            case "SESSION_KEY_BUSY": self = .busy
            case "DEVICE_HAS_SESSION_KEY": self = .deviceHasSessionKey
            case "INVALID_REPLACEMENT": self = .invalidReplacement
            case "SESSION_KEY_LIMIT_REACHED": self = .limitReached
            case "SESSION_KEY_NOT_TOGGLEABLE": self = .notToggleable
            case "SESSION_KEY_NOT_FOUND": self = .notFound
            case "RELAYER_REJECTED": self = .relayerRejected
            case "NONCE_ALREADY_USED": self = .nonceAlreadyUsed
            default: self = .unknown(apiValue)
            }
        }
    }

    init(apiError: PolymarketAPIError) {
        guard apiError.isClientRefusal, case .http(let statusCode, let problemDetail) = apiError else {
            self = .other(apiError)
            return
        }

        self = .refused(
            statusCode: statusCode,
            reason: Reason(apiValue: problemDetail?.reason),
            detail: problemDetail?.detail
        )
    }

    var isRetryableWithTheSameRequest: Bool {
        switch self {
        case .other(let apiError): apiError.isTransient
        case .refused, .cancelled: false
        }
    }
}
