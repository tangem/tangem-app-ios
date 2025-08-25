//
//  NFTCachedModels.V1.Collection.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension NFTCachedModels.V1 {
    struct Collection: Codable {
        // MARK: - NFTCollectionId

        let collectionIdentifier: String
        let ownerAddress: String
        let chainName: String
        let isTestnet: Bool

        // MARK: - NFTCollection

        let contractTypeIdentifier: String
        let name: String
        let description: String?
        let assetsCount: Int

        // MARK: - NFTMedia

        let mediaURL: URL?
        let mediaKindName: String?

        // MARK: - Assets (nested array)

        let errorDescriptors: [ErrorDescriptor]
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

        // From NFTContractType using shared utility
        contractTypeIdentifier = NFTCachedModels.ContractTypeUtils.serialize(collection.contractType)

        // From main NFTCollection
        name = collection.name
        description = collection.description
        assetsCount = collection.assetsCount

        // From NFTMedia using shared utility
        if let media = collection.media {
            mediaURL = media.url
            mediaKindName = NFTCachedModels.MediaUtils.serialize(media.kind)
        } else {
            mediaURL = nil
            mediaKindName = nil
        }

        // Store assets as Asset objects

        errorDescriptors = collection.assetsResult.errors.map { NFTCachedModels.V1.ErrorDescriptor(from: $0) }
        assets = collection.assetsResult.value.map { NFTCachedModels.V1.Asset(from: $0) }
    }

    func toNFTCollection() throws -> NFTCollection {
        // Reconstruct chain using shared utility
        let chain = try NFTCachedModels.ChainUtils.deserialize(chainName: chainName, isTestnet: isTestnet)

        // Reconstruct contract type using shared utility
        let contractType = NFTCachedModels.ContractTypeUtils.deserialize(contractTypeIdentifier: contractTypeIdentifier)

        // Reconstruct media using shared utility
        var media: NFTMedia?
        if let mediaURL, let mediaKindName {
            media = NFTCachedModels.MediaUtils.createMedia(url: mediaURL, kindName: mediaKindName)
        }

        // Reconstruct ErrorDescriptors
        let errorDescriptors = errorDescriptors.map { $0.toNFTErrorDescriptor() }

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
            assetsResult: NFTPartialResult(value: assetsArray, errors: errorDescriptors)
        )
    }
}
