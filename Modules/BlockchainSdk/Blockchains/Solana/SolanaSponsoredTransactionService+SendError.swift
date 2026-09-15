//
//  SolanaSponsoredTransactionService+SendError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

public extension SolanaSponsoredTransactionService {
    enum SendError: Error {
        /// The node already holds this exact transaction, so an earlier attempt reached the chain and only
        /// its response was lost.
        case alreadyProcessed
    }
}

extension SolanaSponsoredTransactionService {
    /// The node answers every rejected simulation with the same code, so the message is the only thing that
    /// separates a transaction it already holds from one it refused — and the two must not be confused: a
    /// refused transaction never reached the chain and has to keep failing.
    static func sendError(from error: any Error) -> any Error {
        guard case SolanaError.invalidResponse(let response) = error,
              let message = response.message,
              message.localizedCaseInsensitiveContains(Constants.alreadyProcessedMarker) else {
            return error
        }

        return SendError.alreadyProcessed
    }

    private enum Constants {
        static let alreadyProcessedMarker = "already been processed"
    }
}
