//
//  Untitled.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct Asset: Decodable {
        let associatedTokenAddress: String?
        let mint: String?
        let name: String?
        let symbol: String?
        let amount: String?
        let amountRaw: String?
        let decimals: Int?
        let totalSupply: String?
        let attributes: [Attribute]?
        let contract: Contract?
        let collection: Collection?
        let firstCreated: FirstCreated?
        let creators: [Creator]?
        let properties: Properties?
    }
}
