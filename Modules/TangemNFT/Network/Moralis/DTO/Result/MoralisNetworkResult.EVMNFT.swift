//
//  MoralisNetworkResult.EVMNFT.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkResult {
    struct EVMNFT: Decodable {
        let amount: String
        let tokenId: String
        let tokenAddress: String
        let contractType: String // [REDACTED_TODO_COMMENT]
        let ownerOf: String
        let lastMetadataSync: String
        let lastTokenURISync: String // [REDACTED_TODO_COMMENT]
        let metadata: String?
        let blockNumber: String
        let blockNumberMinted: String?
        let name: String
        let symbol: String
        let tokenHash: String
        let tokenURI: String // [REDACTED_TODO_COMMENT]
        let minterAddress: String?
        let rarityRank: Int?
        let rarityPercentage: Double?
        let rarityLabel: String?
        let verifiedCollection: Bool
        let possibleSpam: Bool
        let media: Media?
        let collectionLogo: String?
        let collectionBannerImage: String?
        let floorPrice: String?
        let floorPriceUSD: String? // [REDACTED_TODO_COMMENT]
        let floorPriceCurrency: String?
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkResult.EVMNFT {
    struct Media: Decodable {
        let status: String // [REDACTED_TODO_COMMENT]
        let updatedAt: String
        let mimeType: String // [REDACTED_TODO_COMMENT]
        let parentHash: String
        let mediaCollection: MediaCollection?
        let originalMediaURL: String // [REDACTED_TODO_COMMENT]
    }

    struct MediaCollection: Decodable {
        let low: MediaDetail?
        let medium: MediaDetail?
        let high: MediaDetail?
    }

    struct MediaDetail: Decodable {
        let height: Int
        let width: Int
        let url: String
    }
}
