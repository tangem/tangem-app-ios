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
        switch contractType?.lowercased() {
        case "erc721":
            return .erc721
        case "erc1155":
            return .erc1155
        case "splToken":
            return .splToken
        case "splToken2022":
            return .splToken2022
        case "tep62":
            return .tep62
        default:
            return .unknown
        }
    }
}
