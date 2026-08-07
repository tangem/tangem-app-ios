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

    /// Total confirmed cashback earned in the current period, in `currency`
    public let confirmedAmount: String?

    /// Currency of amount fields. Always USD
    public let currency: String?
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
        public let payoutStartDate: String

        /// 5th of next calendar month, UTC. BFF hardcode
        public let payoutEndDate: String
    }
}
