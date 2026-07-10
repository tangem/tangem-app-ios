//
//  PromotionRegistrationDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromotionRegistrationDTO {
    struct Request: Encodable {
        let campaignId: String
        let walletIds: [String]
        let tokenReward: TokenReward

        struct TokenReward: Encodable {
            let tokenAddress: String?
            let networkId: String
            let userAddress: String
        }
    }

    struct Response: Decodable {
        let status: Status

        enum Status: String, Decodable {
            case saved
            case alreadyExists = "already_exists"
        }
    }
}
