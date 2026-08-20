//
//  PolymarketDerivationError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum PolymarketDerivationError: Error, Equatable {
    case derivationUnsupported
    case missingWallet
    case cancelled
    case cardFailed
    case keyNotDerived
    case addressCreationFailed
    case unknown
}

extension PolymarketDerivationError {
    init(derivationFailure error: Error) {
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
