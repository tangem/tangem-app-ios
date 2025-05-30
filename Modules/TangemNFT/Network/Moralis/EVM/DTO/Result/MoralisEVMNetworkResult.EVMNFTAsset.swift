//
//  MoralisNetworkResult.EVMNFTAsset.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import AnyCodable

extension MoralisEVMNetworkResult {
    struct EVMNFTAsset: Decodable {
        let amount: String?
        let tokenId: String?
        let tokenAddress: String?
        let contractType: String?
        let ownerOf: String?
        let lastMetadataSync: String?
        let lastTokenUriSync: String?
        /// Embedded JSON string.
        let metadata: String?
        let normalizedMetadata: NormalizedMetadata?
        let blockNumber: String?
        let blockNumberMinted: String?
        let name: String?
        let symbol: String?
        let tokenHash: String?
        let tokenUri: String?
        let minterAddress: String?
        let rarityRank: Double?
        let rarityPercentage: Double?
        let rarityLabel: String?
        let verifiedCollection: Bool?
        let possibleSpam: Bool?
        let media: Media?
        let collectionLogo: String?
        let collectionBannerImage: String?
        let floorPrice: String?
        let floorPriceUsd: String?
        let floorPriceCurrency: String?
    }
}

// MARK: - Nested DTOs

extension MoralisEVMNetworkResult.EVMNFTAsset {
    struct NormalizedMetadata: Decodable {
        let name: String?
        let description: String?
        let animationUrl: String?
        let externalLink: String?
        let image: String?
        let attributes: [Attribute]?
    }

    struct Attribute: Decodable {
        let traitType: String?
        let value: AnyDecodable?
        let maxValue: AnyDecodable?
        let displayType: String?
        let traitCount: Int?
        let order: String?
        let rarityLabel: String?
        let count: Int?
        let percentage: Double?
    }

    struct Media: Decodable {
        let status: String?
        let updatedAt: String?
        let mimetype: String?
        let parentHash: String?
        let mediaCollection: MediaCollection?
        let originalMediaUrl: String?
    }

    struct MediaCollection: Decodable {
        let low: MediaDetail?
        let medium: MediaDetail?
        let high: MediaDetail?
    }

    struct MediaDetail: Decodable {
        let height: Int?
        let width: Int?
        let url: String?
    }
}
