//
//  PolymarketSigningError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum PolymarketSigningError: Error {
    case notDerived
    case cancelled
    case cardFailed
    case addressCreationFailed
    case unknown
}

public extension PolymarketSigningError {
    init(signingFailure error: Error) {
        if error is CancellationError {
            self = .cancelled
            return
        }

        guard let sdkError = error as? TangemSdkError else {
            self = .unknown
            return
        }

        self = sdkError.isUserCancelled ? .cancelled : .cardFailed
    }
}
