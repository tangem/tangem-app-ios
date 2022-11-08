//
//  ReferralModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum ReferralDiscountType: String, Decodable {
    case percentage

    var symbol: String {
        "%"
    }
}

struct ReferralConditions: Decodable {
    let award: Decimal
    let discount: Int
    let discountType: ReferralDiscountType
    let touLink: String
    let tokens: [ReferralToken]
}

struct ReferralInfo: Decodable {
    let shareLink: String
    let address: String
    let promoCode: String
    let walletPurchase: Int
}

struct ReferralToken: Decodable {
    let id: String
    let name: String
    let symbol: String
    let networkId: String
    let contractAddress: String
    let decimalCount: Int
}

struct ReferralProgramInfo: Decodable {
    let conditions: ReferralConditions
    let referral: ReferralInfo?
}
