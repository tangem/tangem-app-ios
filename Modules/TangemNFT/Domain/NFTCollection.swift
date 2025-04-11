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
    public let contractType: NFTContractType
    public let name: String
    public let description: String?
    public let logoURL: URL?
    /// - Note: Some NFT providers (Moralis for example) do not return assets in collections;
    /// therefore this property should always be used if you need to determine the number of assets.
    /// Do not use `assets.count` for this purpose.
    public let assetsCount: Int
    public let assets: [NFTAsset]

    init(
        collectionIdentifier: String,
        chain: NFTChain,
        contractType: NFTContractType,
        ownerAddress: String,
        name: String,
        description: String?,
        logoURL: URL?,
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
        self.logoURL = logoURL
        self.assetsCount = assetsCount ?? assets.count
        self.assets = assets
    }
}

// MARK: - Auxiliary types

public extension NFTCollection {
    struct NFTCollectionId: Hashable, Sendable {
        /// Collection's address.
        public let collectionIdentifier: String
        /// The owner's address is intentionally a part of the collection identity
        /// to distinguish between identical collections but with different derivations.
        public let ownerAddress: String
        public let chain: NFTChain
    }
}
