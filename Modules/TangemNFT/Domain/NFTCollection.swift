//
//  NFTCollection.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTCollection: Hashable, Identifiable, Sendable {
    public let id: NFTCollectionId
    let contractType: NFTContractType
    let name: String
    let description: String?
    let media: NFTMedia?
    /// - Note: Some NFT providers (Moralis for example) do not return assets in collections;
    /// therefore this property should always be used if you need to determine the number of assets.
    /// Do not use `assets.count` for this purpose.
    let assetsCount: Int
    let assets: [NFTAsset]

    init(
        collectionIdentifier: String,
        chain: NFTChain,
        contractType: NFTContractType,
        ownerAddress: String,
        name: String,
        description: String?,
        media: NFTMedia?,
        assetsCount: Int?,
        assets: [NFTAsset]
    ) {
        id = .init(
            collectionIdentifier: collectionIdentifier,
            ownerAddress: ownerAddress,
            chain: chain
        )

        self.contractType = contractType
        self.name = name
        self.description = description
        self.media = media
        self.assetsCount = assetsCount ?? assets.count
        self.assets = assets
    }
}

// MARK: - Convenience extensions

public extension NFTCollection {
    /// - Note: Some NFT providers (Moralis for example) do not return assets in collections;
    /// therefore, this helper can be used to enrich existing domain models of NFT collection with NFT assets fetched separately.
    func enriched(with assets: [NFTAsset]) -> Self {
        return .init(
            collectionIdentifier: id.collectionIdentifier,
            chain: id.chain,
            contractType: contractType,
            ownerAddress: id.ownerAddress,
            name: name,
            description: description,
            media: media,
            assetsCount: assets.count,
            assets: assets
        )
    }
}

// MARK: - Auxiliary types

public extension NFTCollection {
    struct NFTCollectionId: Hashable, Sendable {
        /// Collection's address.
        let collectionIdentifier: String
        /// The owner's address is intentionally a part of the collection identity
        /// to distinguish between identical collections but with different derivations.
        public let ownerAddress: String
        public let chain: NFTChain

        public static let dummy = Self(
            collectionIdentifier: UUID().uuidString,
            ownerAddress: UUID().uuidString,
            chain: .arbitrum
        )
    }
}
