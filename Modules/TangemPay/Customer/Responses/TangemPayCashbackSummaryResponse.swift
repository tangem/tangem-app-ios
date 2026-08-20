//
//  TangemPayCashbackSummaryResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCashbackSummaryResponse: Decodable {
    public let cashbackProgramStatus: Status

    /// Every field below is omitted unless `cashbackProgramStatus` is `.enabled`.
    public let cashbackDisplayMode: Mode?
    public let period: Period?
    public let confirmedAmount: String?
    public let totalEarnedAmount: String?
    public let previousPayoutEndDate: String?
    public let previousPayoutAmount: String?
    public let currency: String?
    public let payoutCurrency: String?
}

// MARK: - Nested Types

public extension TangemPayCashbackSummaryResponse {
    enum Status: String, Decodable {
        case enabled
        case fraud
        case disabled
        case undefined

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue) ?? .undefined
        }
    }

    enum Mode: String, Decodable {
        /// Standard cashback UI block
        case full

        /// Alternative block shown to EU customers, who are excluded from in-store purchase cashback
        case altBlock = "alt_block"

        /// Client fallback
        case undefined

        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: rawValue) ?? .undefined
        }
    }

    struct Period: Decodable {
        public let year: Int

        /// Range of 1-12
        public let month: Int

        /// 2nd of next calendar month, UTC. BFF hardcode
        public let payoutStartDate: String?

        /// 5th of next calendar month, UTC. BFF hardcode
        public let payoutEndDate: String?
    }
}
