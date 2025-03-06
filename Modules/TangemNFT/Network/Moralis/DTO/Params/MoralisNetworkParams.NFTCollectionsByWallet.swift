//
//  MoralisNetworkParams.NFTCollectionsByWallet.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTCollectionsByWallet: Encodable {
        let chain: NFTChain?
        let limit: Int?
        let cursor: String?
        let tokenCounts: Bool?
        let excludeSpam: Bool?
    }
}
