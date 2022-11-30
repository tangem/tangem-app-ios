//
//  ReferralModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReferralProgramInfo: Decodable {
    let conditions: Conditions
    let referral: Referral?
}

extension ReferralProgramInfo {
    struct Conditions: Decodable {
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

    struct Discount: Decodable {
        let amount: Int
        let type: DiscountType
    }

    enum DiscountType: String, Decodable {
        case percentage
        case value

        var symbol: String {
            "%"
        }
    }
}
