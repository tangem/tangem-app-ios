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
    public let ownerAddress: String
    public let name: String
    public let description: String?
    public let media: Media?
    public let rarity: Rarity?
    public let traits: [Trait]

    init(
        assetIdentifier: String,
        collectionIdentifier: String,
        chain: NFTChain,
        derivationPath: NFTDerivationPath?,
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
            chain: chain,
            derivationPath: derivationPath
        )

        self.contractType = contractType
        self.ownerAddress = ownerAddress
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
        public let chain: NFTChain
        public let derivationPath: NFTDerivationPath?
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
