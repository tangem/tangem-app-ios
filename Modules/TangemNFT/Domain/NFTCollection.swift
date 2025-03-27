//
//  NFTCollection.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTCollection: Hashable, Identifiable {
    public let id: NFTCollectionId
    public let contractType: NFTContractType
    public let name: String
    public let description: String?
    public let logoURL: URL?
    public let assets: [NFTAsset]

    init(
        collectionIdentifier: String,
        chain: NFTChain,
        derivationPath: NFTDerivationPath?,
        contractType: NFTContractType,
        name: String,
        description: String?,
        logoURL: URL?,
        assets: [NFTAsset]
    ) {
        id = .init(
            collectionIdentifier: collectionIdentifier,
            chain: chain,
            derivationPath: derivationPath
        )
        self.contractType = contractType
        self.name = name
        self.description = description
        self.logoURL = logoURL
        self.assets = assets
    }
}

// MARK: - Auxiliary types

public extension NFTCollection {
    struct NFTCollectionId: Hashable {
        /// Collection's address.
        public let collectionIdentifier: String
        public let chain: NFTChain
        public let derivationPath: NFTDerivationPath?
    }
}
