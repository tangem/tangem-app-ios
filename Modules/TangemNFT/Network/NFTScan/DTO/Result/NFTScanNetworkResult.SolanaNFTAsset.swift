//
//  NFTScanNetworkResult.SolanaNFTAsset.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
extension NFTScanNetworkResult {
    struct Asset: Decodable {
        let blockNumber: Int
        let interactProgram: String
        let collection: String?
        let tokenAddress: String
        let minter: String
        let owner: String
        let mintTimestamp: Int
        let mintTransactionHash: String
        let mintPrice: Decimal
        let tokenUri: String
        let metadataJson: String?
        let name: String
        let contentType: String?
        let contentUri: String?
        let imageUri: String?
        let externalLink: String?
        let latestTradePrice: Decimal?
        let latestTradeSymbol: String?
        let latestTradeToken: String?
        let latestTradeTimestamp: Int?
        let latestTradeTransactionHash: String?
    }
}
