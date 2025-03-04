//
//  MoralisNetworkResult.EVMNFTCollections.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkResult {
    struct EVMNFTCollections: Codable {
        let status: String // [REDACTED_TODO_COMMENT]
        let page: Int
        let cursor: String?
        let pageSize: Int
        let result: [Collection]
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkResult.EVMNFTCollections {
    struct Collection: Codable {
        let tokenAddress: String
        let possibleSpam: Bool
        let contractType: String // [REDACTED_TODO_COMMENT]
        let name: String
        let symbol: String
        let verifiedCollection: Bool
        let collectionLogo: String?
        let collectionBannerImage: String?
        let floorPrice: String?
        let floorPriceUsd: String?
        let floorPriceCurrency: String?
        let count: Int?
    }
}
