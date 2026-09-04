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
        let minCheckoutUsd: Decimal

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
        let evm: String?
        let svm: String?
        let btc: String?
        let tron: String?
    }
}

// MARK: - Tron key

extension PolymarketDTO.FundingAddressesResponse {
    private enum CodingKeys: String, CodingKey {
        case evm
        case svm
        case btc
        case tron
        case tvm
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        evm = try container.decodeIfPresent(String.self, forKey: .evm)
        svm = try container.decodeIfPresent(String.self, forKey: .svm)
        btc = try container.decodeIfPresent(String.self, forKey: .btc)
        tron = try container.decodeIfPresent(String.self, forKey: .tron) ?? container.decodeIfPresent(String.self, forKey: .tvm)
    }
}
