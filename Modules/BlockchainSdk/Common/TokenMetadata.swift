//
//  TokenMetadata.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TokenMetadata: Hashable, Codable {
    public static var fungibleTokenMetadata: TokenMetadata {
        return TokenMetadata(kind: .fungible)
    }

    public let kind: Kind
    public let yieldSupply: TokenYieldSupply?

    public init(kind: Kind, yieldSupply: TokenYieldSupply? = nil) {
        self.kind = kind
        self.yieldSupply = yieldSupply
    }
}

// MARK: - Nested types

public extension TokenMetadata {
    enum Kind: Hashable, Codable {
        case fungible
        case nonFungible(assetIdentifier: String, contractType: ContractType)
    }

    enum ContractType: Hashable, Codable {
        /// https://eips.ethereum.org/EIPS/eip-721
        case erc721
        /// https://eips.ethereum.org/EIPS/eip-1155
        case erc1155
        /// Unspecified contract type (for example for Solana the contract type doesn't matter)
        case unspecified
    }
}
