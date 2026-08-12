//
//  TangemPayCashbackPromotionsResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCashbackPromotionsResponse: Decodable {
    public let cashbackOnCards: CashbackOnCards?

    @DefaultIfMissing
    public var additionalCashback: [AdditionalCashback]
}

// MARK: - Nested Types

public extension TangemPayCashbackPromotionsResponse {
    struct CashbackOnCards: Decodable {
        @DefaultIfMissing
        public var tiers: [Tier]

        public let accountMonthlyCapAmount: String?
        public let accountMonthlyCapCurrency: String?

        public struct Tier: Codable {
            public let tier: TangemPayCashbackTier
            public let tierCashbackRate: String
            public let minTransactionAmount: String?
            public let tierMonthlyCapAmount: String?
            public let promotionId: String
        }
    }

    struct AdditionalCashback: Codable {
        public let id: String
        public let tier: TangemPayCashbackTier
        public let name: String
        public let description: String?
        public let endDate: String?
        public let promoCapAmount: String?
        public let promoCapPeriod: CapPeriod?
        public let capCurrency: String?
        public let minTransactionAmount: String?

        /// Range of 0-99, a higher number means a higher position in the list
        public let priority: Int
    }

    enum CapPeriod: String, Codable {
        case monthly
        case lifetime
        case undefined

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue) ?? .undefined
        }
    }
}

// MARK: - TangemPayCashbackTier

public enum TangemPayCashbackTier: String, Codable {
    case basic
    case plus
    case plusFF = "plus_ff"
    case undefined

    public init(from decoder: Decoder) throws {
        let rawValue = try? decoder.singleValueContainer().decode(String.self)
        self = rawValue.flatMap(Self.init(rawValue:)) ?? .undefined
    }
}
