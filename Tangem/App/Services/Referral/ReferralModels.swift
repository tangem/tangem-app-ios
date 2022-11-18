//
//  ReferralModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReferralProgramInfo: Decodable {
    struct Conditions: Decodable {
        struct Discount: Decodable {
            enum DiscountType: String, Decodable {
                case percentage

                var symbol: String {
                    "%"
                }
            }

            let amount: Int
            let type: DiscountType
        }

        struct Award: Decodable {
            let amount: Decimal
            let token: Token
        }

        struct Token: Decodable {
            let id: String
            let name: String
            let symbol: String
            let networkId: String
            let contractAddress: String?
            let decimalCount: Int?
        }

        let discount: Discount
        let tosLink: String
        let awards: [Award]
    }

    struct Referral: Decodable {
        let shareLink: String
        let address: String
        let promoCode: String
        let walletsPurchased: Int
    }

    let conditions: Conditions
    let referral: Referral?

}
