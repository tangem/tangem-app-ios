//
//  PolymarketDerivationError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum PolymarketDerivationError: Error, Equatable {
    case derivationUnsupported
    case missingWallet
    case cancelled
    case cardFailed
    case keyNotDerived
    case addressCreationFailed
    case unknown
}

public extension PolymarketDerivationError {
    init(derivationFailure error: Error) {
        if error is CancellationError {
            self = .cancelled
            return
        }

        guard let sdkError = error as? TangemSdkError else {
            self = .unknown
            return
        }

        if sdkError.isUserCancelled {
            self = .cancelled
        } else if case .walletNotFound = sdkError {
            self = .missingWallet
        } else {
            self = .cardFailed
        }
    }
}
