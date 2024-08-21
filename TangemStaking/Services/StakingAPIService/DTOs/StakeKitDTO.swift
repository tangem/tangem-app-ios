//
//  StakeKitDTO.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum StakeKitDTO {
    // MARK: - Common

    struct APIError: Decodable, Error {
        let message: String?
        let level: String?
    }

    struct Token: Codable {
        let coinGeckoId: String
        let network: String?
        let name: String?
        let decimals: Int?
        let address: String?
        let symbol: String?
        let logoURI: String?
    }

    struct Validator: Decodable {
        let address: String
        let status: Status
        let name: String?
        let image: String?
        let website: String?
        let apr: Decimal?
        let commission: Decimal?
        let stakedBalance: String?
        let votingPower: Decimal?
        let preferred: Bool?

        enum Status: String, Decodable {
            case active
            case jailed
            case deactivating
            case inactive
        }
    }

    struct Address: Codable {
        let address: String
    }

    struct Required: Decodable {
        let required: Bool
    }
}
