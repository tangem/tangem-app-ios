//
//  BlockchainScanResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct BlockaidChainScanResult: Equatable {
    let validationStatus: ValidationStatus?
    let validationDescription: String
    let assetsDiff: AssetDiff?
    let approvals: [Asset]?

    enum ValidationStatus {
        case malicious
        case warning
        case benign
        case error
    }

    struct AssetDiff: Equatable {
        let `in`: [Asset]
        let out: [Asset]
    }

    struct Asset: Hashable {
        let name: String?
        let assetType: String
        let amount: Decimal?
        let symbol: String?
        let logoURL: URL?
        let decimals: Int?
        let contractAddress: String? // Contract address from Blockaid API

        /// Determines if the asset is an NFT based on assetType
        var isNFT: Bool {
            return assetType.lowercased() == "erc721" ||
                assetType.lowercased() == "erc1155" ||
                assetType.lowercased() == "nft"
        }
    }
}
