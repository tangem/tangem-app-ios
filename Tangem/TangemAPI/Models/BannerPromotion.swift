//
//  BannerPromotion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum BannerPromotion {}

extension BannerPromotion {
    struct Timeline: Codable, Hashable {
        let start: Date
        let end: Date
    }

    struct Request: Encodable {
        let walletId: String
    }

    struct Response: Decodable {
        let promotions: [Promotion]

        struct Promotion: Decodable {
            let name: String
            let all: Info
        }

        struct Info: Decodable {
            let timeline: Timeline
            let tokens: [Token]
            let status: Status
            let link: String?
        }

        /// `tokenId` and `decimals` are present only for cashback payout tokens; yield-boost tokens carry only the base fields.
        struct Token: Decodable {
            let tokenId: String?
            let tokenAddress: String
            let tokenSymbol: String
            let tokenName: String
            let networkId: String
            let decimals: Int?
        }

        /// Server filters out non-active campaigns, but the enum stays open for safety.
        enum Status: String, Decodable {
            case active
            case pending
            case finished
        }
    }
}
