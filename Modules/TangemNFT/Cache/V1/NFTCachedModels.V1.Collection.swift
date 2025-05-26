//
//  NFTCachedModels.V1.Collection.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTCachedModels.V1 {
    struct Collection: Codable, Hashable, Identifiable, Sendable {
        // From NFTCollectionId
        let id: String // Combination of identifier and other fields to ensure uniqueness
        let collectionIdentifier: String
        let ownerAddress: String
        let chainName: String // String representation of NFTChain
        let isTestnet: Bool // Whether the chain is testnet

        // From main NFTCollection
        let contractTypeIdentifier: String // String representation of NFTContractType
        let name: String
        let description: String?

        // From NFTMedia
        let mediaURL: URL?
        let mediaKindName: String?

        /// Collection stats
        let assetsCount: Int

        /// Nested array of Asset objects
        let assets: [Asset]
    }
}

extension NFTCachedModels.V1.Collection {
    init(from collection: NFTCollection) {
        // From NFTCollectionId
        collectionIdentifier = collection.id.collectionIdentifier
        ownerAddress = collection.id.ownerAddress

        // Extract chain info using shared utility
        let (chainNameValue, isTestnetValue) = NFTCachedModels.ChainUtils.serialize(collection.id.chain)
        chainName = chainNameValue
        isTestnet = isTestnetValue

        // Create unique ID by combining key fields
        id = "\(chainName)\(isTestnet ? "-testnet" : "")_\(collectionIdentifier)_\(ownerAddress)"

        // From NFTContractType using shared utility
        contractTypeIdentifier = NFTCachedModels.ContractTypeUtils.serialize(collection.contractType)

        // From main NFTCollection
        name = collection.name
        description = collection.description
        assetsCount = collection.assetsCount

        // From NFTMedia using shared utility
        mediaURL = collection.media?.url
        mediaKindName = NFTCachedModels.MediaUtils.serialize(collection.media?.kind)

        // Store assets as Asset objects
        assets = collection.assets.map { NFTCachedModels.V1.Asset(from: $0) }
    }

    func toNFTCollection() throws -> NFTCollection {
        // Reconstruct chain using shared utility
        let chain = try NFTCachedModels.ChainUtils.deserialize(chainName: chainName, isTestnet: isTestnet)

        // Reconstruct contract type using shared utility
        let contractType = NFTCachedModels.ContractTypeUtils.deserialize(contractTypeIdentifier: contractTypeIdentifier)

        // Reconstruct media using shared utility
        let media = NFTCachedModels.MediaUtils.createMedia(url: mediaURL, kindName: mediaKindName)

        // Convert stored Asset objects to NFTAsset domain objects
        let assetsArray = try assets.map { try $0.toNFTAsset() }

        // Create the NFTCollection with all reconstructed components
        return NFTCollection(
            collectionIdentifier: collectionIdentifier,
            chain: chain,
            contractType: contractType,
            ownerAddress: ownerAddress,
            name: name,
            description: description,
            media: media,
            assetsCount: assetsCount,
            assets: assetsArray
        )
    }
}
