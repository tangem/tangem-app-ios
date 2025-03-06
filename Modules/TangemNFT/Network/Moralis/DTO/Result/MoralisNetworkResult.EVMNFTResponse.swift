//
//  MoralisNetworkResult.EVMNFTResponse.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkResult {
    /// Generic paginated response for `api/{version}/{address}/nft/collections` and `api/{version}/{address}/nft`.
    struct EVMNFTResponse<T: Decodable>: Decodable {
        let status: Status
        let page: Int
        let pageSize: Int
        let cursor: String?
        let result: T
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkResult.EVMNFTResponse {
    enum Status: String, Decodable {
        case synced = "SYNCED"
        case syncing = "SYNCING"
    }
}
