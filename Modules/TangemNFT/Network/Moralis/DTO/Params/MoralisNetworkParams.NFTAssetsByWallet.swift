//
//  MoralisNetworkParams.NFTAssetsByWallet.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    struct NFTAssetsByWallet: Encodable {
        let chain: NFTChain?
        let format: Format?
        let limit: Int?
        let cursor: String?
        let excludeSpam: Bool?
        let tokenAddresses: [String]?
        let normalizeMetadata: Bool?
        let mediaItems: Bool?
        let includePrices: Bool?
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkParams.NFTAssetsByWallet {
    enum Format: Encodable {
        case decimal
        case hex
    }
}
