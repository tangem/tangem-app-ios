//
//  CollectiblesSendError.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SolanaSwift

public enum CollectiblesSendError: Error {
    case transactionExpired
    case rejected(any Error)
    case outcomeUnknown

    init(classifying error: any Error, blockhashFetchedAt: Date) {
        guard !Self.isBlockhashNotFound(error) else {
            self = .transactionExpired
            return
        }

        guard Self.isRejectedByNode(error) else {
            self = .outcomeUnknown
            return
        }

        guard Date().timeIntervalSince(blockhashFetchedAt) > Constants.blockhashLifetime else {
            self = .rejected(error)
            return
        }

        self = .transactionExpired
    }
}

// MARK: - Private logic

private extension CollectiblesSendError {
    static func isBlockhashNotFound(_ error: any Error) -> Bool {
        let response: ResponseError? = switch error {
        case RPCError.invalidResponse(let response): response
        case SolanaError.invalidResponse(let response): response
        default: nil
        }

        return response?.message?.localizedCaseInsensitiveContains(Constants.blockhashNotFoundMarker) == true
    }

    static func isRejectedByNode(_ error: any Error) -> Bool {
        switch error {
        case RPCError.invalidResponse, SolanaError.invalidResponse, is SolanaSendError, is CollectiblesProgramRejection:
            true
        default:
            false
        }
    }
}

// MARK: - Constants

private extension CollectiblesSendError {
    enum Constants {
        static let blockhashNotFoundMarker = "Blockhash not found"
        static let blockhashLifetime: TimeInterval = 120
    }
}
