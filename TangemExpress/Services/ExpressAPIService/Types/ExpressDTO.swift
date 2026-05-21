//
//  ExpressDTO.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ExpressDTO {
    // MARK: - Common

    struct Currency: Codable {
        let contractAddress: String
        let network: String
    }

    // MARK: - History (shared primitives — same shape in /v1/exchange/history and /v1/onramp/history)

    struct HistoryRequest: Encodable {
        let walletAddress: String
        let cursor: String?
        let limit: Int?
        let network: String?
        let tokenId: String?

        enum CodingKeys: String, CodingKey {
            case walletAddress = "wallet_address"
            case cursor
            case limit
            case network
            case tokenId = "token_id"
        }
    }

    struct HistoryProvider: Decodable {
        let id: String
        let name: String
        let iconUrl: String
        let providerUrl: String

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case iconUrl = "icon_url"
            case providerUrl = "provider_url"
        }
    }

    // MARK: - Error

    enum APIError {
        struct Response: Decodable {
            let error: ExpressAPIError
        }
    }
}
