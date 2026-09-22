//
//  PolymarketDTO+Bridge.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct SupportedAssetsResponse: Decodable {
        let supportedAssets: [SupportedAsset]
    }

    struct SupportedAsset: Decodable {
        let chainId: String
        let chainName: String
        let token: Token
        let minCheckoutUsd: Decimal?

        struct Token: Decodable {
            let name: String
            let symbol: String
            let address: String
            let decimals: Int
        }
    }

    struct DepositRequest: Encodable {
        let address: String
    }

    struct FundingAddressesResponse: Decodable {
        let address: Addresses

        struct Addresses: Decodable {
            let evm: String?
            let svm: String?
            let btc: String?
            let tron: String?
        }
    }
}
