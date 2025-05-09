//
//  NFTContractTypeMapper.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// - Note: Shared between `Moralis`, `NFTScan` and other providers.
struct NFTContractTypeMapper {
    func map(contractType: String?) -> NFTContractType {
        guard let contractType else {
            return .unknown
        }

        switch contractType.lowercased() {
        case "erc721":
            return .erc721
        case "erc1155":
            return .erc1155
        default:
            return .other(contractType)
        }
    }
}
