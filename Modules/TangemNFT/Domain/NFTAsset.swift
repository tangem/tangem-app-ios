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
    public let decimalCount: Int
    public let name: String
    let description: String?
    let salePrice: NFTSalePrice?
    let mediaFiles: [NFTMedia]
    let rarity: Rarity?
    let traits: [Trait]

    init(
        assetIdentifier: String,
        assetContractAddress: String,
        chain: NFTChain,
        contractType: NFTContractType,
        decimalCount: Int,
        ownerAddress: String,
        name: String,
        description: String?,
        salePrice: NFTSalePrice?,
        mediaFiles: [NFTMedia],
        rarity: NFTAsset.Rarity?,
        traits: [NFTAsset.Trait]
    ) {
        id = .init(
            identifier: assetIdentifier,
            contractAddress: assetContractAddress,
            ownerAddress: ownerAddress,
            chain: chain,
            contractType: contractType
        )

        self.decimalCount = decimalCount
        self.name = name
        self.description = description
        self.salePrice = salePrice
        self.mediaFiles = mediaFiles
        self.rarity = rarity
        self.traits = traits
    }
}

// MARK: - Auxiliary types

public extension NFTAsset {
    struct NFTAssetId: Hashable, Sendable {
        /// NFT's unique token id within the collection, if any.
        public let identifier: String
        /// Contract address of the asset.
        public let contractAddress: String
        /// The owner's address is intentionally a part of the asset identity
        /// to distinguish between identical assets but with different derivations.
        public let ownerAddress: String
        public let chain: NFTChain
        public let contractType: NFTContractType
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

// MARK: - Convenience extensions

public extension NFTAsset {
    /// - Note: Some providers provide sale prices as a separate request,
    /// so this helper method can be used to enrich the asset domain model with sale price data.
    func enriched(with salePrice: NFTSalePrice?) -> Self {
        return .init(
            assetIdentifier: id.identifier,
            assetContractAddress: id.contractAddress,
            chain: id.chain,
            contractType: id.contractType,
            decimalCount: decimalCount,
            ownerAddress: id.ownerAddress,
            name: name,
            description: description,
            salePrice: salePrice,
            mediaFiles: mediaFiles,
            rarity: rarity,
            traits: traits
        )
    }
}
