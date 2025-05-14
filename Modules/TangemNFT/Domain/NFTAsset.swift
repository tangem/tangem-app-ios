//
//  NFTAsset.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTAsset: Hashable, Identifiable, Sendable {
    public let id: NFTAssetId
    let contractType: NFTContractType
    let name: String
    let description: String?
    let media: NFTMedia?
    let rarity: Rarity?
    let traits: [Trait]

    init(
        assetIdentifier: String,
        collectionIdentifier: String?,
        chain: NFTChain,
        contractType: NFTContractType,
        ownerAddress: String,
        name: String,
        description: String?,
        media: NFTMedia?,
        rarity: NFTAsset.Rarity?,
        traits: [NFTAsset.Trait]
    ) {
        id = .init(
            assetIdentifier: assetIdentifier,
            collectionIdentifier: collectionIdentifier,
            ownerAddress: ownerAddress,
            chain: chain
        )

        self.contractType = contractType
        self.name = name
        self.description = description
        self.media = media
        self.rarity = rarity
        self.traits = traits
    }
}

// MARK: - Auxiliary types

public extension NFTAsset {
    struct NFTAssetId: Hashable, Sendable {
        /// NFT's unique token id within collection.
        public let assetIdentifier: String
        /// Collection's address.
        public let collectionIdentifier: String?
        /// The owner's address is intentionally a part of the asset identity
        /// to distinguish between identical assets but with different derivations.
        public let ownerAddress: String
        public let chain: NFTChain
    }

    struct Rarity: Hashable, Sendable {
        let label: String?
        let percentage: Double?
        let rank: Int?
    }

    struct Trait: Hashable, Sendable {
        let name: String
        let value: String
    }
}
