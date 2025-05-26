//
//  NFTStorableCollectionModels.swift
//  TangemNFT
//
//  Created on 25.05.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTStorableModels.V1 {
    struct NFTCollectionPOSS: Codable, Hashable, Identifiable, Sendable {
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

        // Collection stats
        let assetsCount: Int

        // Nested array of NFTAssetPOSS objects
        let assets: [NFTAssetPOSS]
    }
}

extension NFTStorableModels.V1.NFTCollectionPOSS {
    init(from collection: NFTCollection) {
        // From NFTCollectionId
        collectionIdentifier = collection.id.collectionIdentifier
        ownerAddress = collection.id.ownerAddress

        // Extract chain info using shared utility
        let (chainNameValue, isTestnetValue) = NFTStorableModels.ChainUtils.serialize(collection.id.chain)
        chainName = chainNameValue
        isTestnet = isTestnetValue

        // Create unique ID by combining key fields
        id = "\(chainName)\(isTestnet ? "-testnet" : "")_\(collectionIdentifier)_\(ownerAddress)"

        // From NFTContractType using shared utility
        contractTypeIdentifier = NFTStorableModels.ContractTypeUtils.serialize(collection.contractType)

        // From main NFTCollection
        name = collection.name
        description = collection.description
        assetsCount = collection.assetsCount

        // From NFTMedia using shared utility
        mediaURL = collection.media?.url
        mediaKindName = NFTStorableModels.MediaUtils.serialize(collection.media?.kind)

        // Store assets as NFTAssetPOSS objects
        assets = collection.assets.map { NFTStorableModels.V1.NFTAssetPOSS(from: $0) }
    }

    func toNFTCollection() throws -> NFTCollection {
        // Reconstruct chain using shared utility
        let chain = try NFTStorableModels.ChainUtils.deserialize(chainName: chainName, isTestnet: isTestnet)

        // Reconstruct contract type using shared utility
        let contractType = NFTStorableModels.ContractTypeUtils.deserialize(contractTypeIdentifier: contractTypeIdentifier)

        // Reconstruct media using shared utility
        let media = NFTStorableModels.MediaUtils.createMedia(url: mediaURL, kindName: mediaKindName)

        // Convert stored NFTAssetPOSS objects to NFTAsset domain objects
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
