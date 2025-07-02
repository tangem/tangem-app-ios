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
    let assetsDiff: AssetDiff?
    let approvals: [Asset]?

    enum ValidationStatus: String {
        case malicious = "Malicious"
        case warning = "Warning"
        case benign = "Benign"

        var description: String {
            switch self {
            case .malicious:
                "The transaction approves tokens to a known malicious address"
            case .warning:
                "The transaction is likely to be a user-mistake transaction resulting in a loss of assets without any compensation"
            case .benign:
                ""
            }
        }
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

        /// Determines if the asset is a fungible token
        var isFungibleToken: Bool {
            return assetType.lowercased() == "erc20" ||
                assetType.lowercased() == "token"
        }

        /// Determines if the asset is the native currency
        var isNative: Bool {
            return assetType.lowercased() == "native"
        }
    }
}
