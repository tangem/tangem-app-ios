//
//  ReferralModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReferralProgramInfo: Decodable {
    struct Referral: Decodable {
        let shareLink: String
        let address: String
        let promoCode: String
        let walletPurchase: Int
    }

    let conditions: Conditions
    let referral: Referral?

    struct Conditions: Decodable {
        enum DiscountType: String, Decodable {
            case percentage

            var symbol: String {
                "%"
            }
        }

        struct Token: Decodable {
            let id: String
            let name: String
            let symbol: String
            let networkId: String
            let contractAddress: String
            let decimalCount: Int
        }

        let award: Decimal
        let discount: Int
        let discountType: DiscountType
        let touLink: String
        let tokens: [Token]
    }
}
