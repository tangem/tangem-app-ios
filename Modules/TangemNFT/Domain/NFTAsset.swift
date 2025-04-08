//
//  NFTAsset.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTAsset: Hashable, Identifiable {
    public let id: NFTAssetId
    public let contractType: NFTContractType
    public let name: String
    public let description: String?
    public let media: Media?
    public let rarity: Rarity?
    public let traits: [Trait]

    init(
        assetIdentifier: String,
        collectionIdentifier: String,
        chain: NFTChain,
        contractType: NFTContractType,
        ownerAddress: String,
        name: String,
        description: String?,
        media: NFTAsset.Media?,
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
    struct NFTAssetId: Hashable {
        /// NFT's unique token id within collection.
        public let assetIdentifier: String
        /// Collection's address.
        public let collectionIdentifier: String
        /// The owner's address is intentionally a part of the asset identity
        /// to distinguish between identical assets but with different derivations.
        public let ownerAddress: String
        public let chain: NFTChain
    }

    struct Media: Hashable {
        public enum Kind {
            case image
            case animation
            case video
            case audio
        }

        public let kind: Kind
        public let url: URL
    }

    struct Rarity: Hashable {
        public let label: String
        public let percentage: Double?
        public let rank: Int?
    }

    struct Trait: Hashable {
        public let name: String
        public let value: String
    }
}
