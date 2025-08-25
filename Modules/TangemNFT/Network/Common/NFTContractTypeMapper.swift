//
//  NFTContractTypeMapper.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum NFTContractTypeMapper {
    /// Note: `isAnalyticsOnly` param is a temporary solution until we come up with proper mapping for Solana NFTs' contract types
    static func map(contractType: String?, isAnalyticsOnly: Bool = false) -> NFTContractType {
        guard let contractType else {
            return .unknown
        }

        guard !isAnalyticsOnly else {
            return .analyticsOnly(contractType)
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
