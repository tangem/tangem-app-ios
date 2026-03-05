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
            let status: Status
            let link: String?
        }

        enum Status: String, Decodable {
            case active
            case pending
            case finished
        }
    }
}
