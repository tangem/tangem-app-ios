//
//  MoralisNetworkResult.EVMNFTResponse.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisEVMNetworkResult {
    /// Generic paginated response for `api/{version}/{address}/nft/collections` and `api/{version}/{address}/nft`.
    struct EVMNFTResponse<T: Decodable>: Decodable {
        let page: Int?
        let pageSize: Int?
        let cursor: String?
        let result: T
    }
}
