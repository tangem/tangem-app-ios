//
//  ExpressTransactionStatus.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionStatus: String, Codable {
    case unknown
    case preview
    case created
    case exchangeTxSent = "exchange-tx-sent"
    case waiting
    case waitingTxHash = "waiting-tx-hash"
    case expired
    case confirming
    case exchanging
    case sending
    case finished
    case failed
    case txFailed = "tx-failed"
    case refunded
    case verifying
    // [REDACTED_TODO_COMMENT]
    @available(iOS, deprecated: 100000.0, message: "Not present in the Express API (`EExchangeStatus`); Investigate and remove if not used")
    case paused
}

public extension ExpressTransactionStatus {
    /// The provider is holding the transaction until the user completes verification (e.g. KYC).
    /// Single source of truth for whether a verification warning should be surfaced in history and details.
    var requiresVerification: Bool {
        switch self {
        case .verifying:
            return true
        case .unknown, .preview, .created, .exchangeTxSent, .waiting, .waitingTxHash, .expired,
             .confirming, .exchanging, .sending, .finished, .failed, .txFailed, .refunded, .paused:
            return false
        }
    }
}
