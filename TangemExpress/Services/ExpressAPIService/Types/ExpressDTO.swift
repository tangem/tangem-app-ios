//
//  ExpressDTO.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import AnyCodable

enum ExpressDTO {
    // MARK: - Common

    struct Currency: Codable {
        let contractAddress: String
        let network: String
    }

    // MARK: - History (shared DTOs for both exchange & onramp)

    struct HistoryRequest: Encodable {
        let walletAddress: String
        let cursor: AnyEncodable?
        let limit: Int?
        let network: String?
        let tokenId: String?
    }

    struct HistoryProvider: Decodable {
        let id: String
        let name: String
        let iconUrl: String
        let providerUrl: String
    }

    // MARK: - Error

    enum APIError {
        struct Response: Decodable {
            let error: ExpressAPIError
        }
    }
}
