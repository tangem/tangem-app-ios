//
//  MoralisTokenBalanceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum MoralisTokenBalanceError: Error {
    case unsupportedChain(Blockchain)
    case unsupportedNetwork(networkId: String)
    case rateLimited
    case decoding(Error)
    case normalization(Error)
    case network(Error)
}

extension MoralisTokenBalanceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unsupportedChain(let blockchain):
            return "Unsupported blockchain for Moralis token balances: \(blockchain.displayName)"
        case .unsupportedNetwork(let networkId):
            return "Unsupported blockchain networkId for Moralis token balances: \(networkId)"
        case .rateLimited:
            return "Moralis token balances request rate limited (HTTP 429)"
        case .decoding(let error):
            return "Failed to decode Moralis token balances response: \(error.localizedDescription)"
        case .normalization(let error):
            return "Failed to normalize Moralis token balances: \(error.localizedDescription)"
        case .network(let error):
            return "Moralis token balances request failed: \(error.localizedDescription)"
        }
    }
}
