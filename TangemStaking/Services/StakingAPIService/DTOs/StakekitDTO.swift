//
//  StakekitDTO.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// Polygon native
// ethereum-matic-native-staking
// 0x29010F8F91B980858EB298A0843264cfF21Fd9c9

enum StakekitDTO {
    // MARK: - Common

    struct APIError: Decodable, Error {
        let message: String?
        let level: String?
    }

    struct Token: Codable {
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
        let apr: Double?
        let commission: Double?
        let stakedBalance: String?
        let votingPower: Double?
        let preferred: Bool?

        enum Status: String, Decodable {
            case active
            case jailed
            case deactivating
            case inactive
        }
    }

    struct Address: Encodable {
        let address: String
    }

    enum Actions {
        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let addresses: [Address]
                let args: Args
                let integrationId: String

                struct Args: Encodable {
                    let inputToken: Token
                    let amount: String
                    let validatorAddress: String
                }
            }

            struct Response: Decodable {}
        }
    }
}
