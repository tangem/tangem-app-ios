//
//  MoralisTokenBalanceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import BlockchainSdk

enum MoralisTokenBalanceError: Error {
    case unsupportedChain(Blockchain)
    case unsupportedNetwork(networkId: String)
    case decoding(Error)
    case network(Error)
}

extension MoralisTokenBalanceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unsupportedChain(let blockchain):
            return "Unsupported blockchain for Moralis token balances: \(blockchain.displayName)"
        case .unsupportedNetwork(let networkId):
            return "Unsupported blockchain networkId for Moralis token balances: \(networkId)"
        case .decoding(let error):
            return "Failed to decode Moralis token balances response: \(error.localizedDescription)"
        case .network(let error):
            return "Moralis token balances request failed: \(error.localizedDescription)"
        }
    }
}
