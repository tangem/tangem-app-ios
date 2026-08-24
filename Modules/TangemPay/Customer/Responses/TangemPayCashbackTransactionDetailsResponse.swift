//
//  TangemPayCashbackTransactionDetailsResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCashbackTransactionDetailsResponse: Decodable {
    public let cashback: Cashback?
}

// MARK: - Nested Types

public extension TangemPayCashbackTransactionDetailsResponse {
    struct Cashback: Decodable {
        public let status: TangemPayCashbackStatus
        public let amount: String?
        public let currency: String?
        public let exclusionReason: ExclusionReason?
    }

    enum ExclusionReason: String, Decodable, Equatable {
        case merchantCountryExcluded = "merchant_country_excluded"
        case mccExcluded = "mcc_excluded"
        case belowMin = "below-min"
        case monthlyCapReached = "monthly_cap_reached"
        case undefined

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue) ?? .undefined
        }
    }
}
