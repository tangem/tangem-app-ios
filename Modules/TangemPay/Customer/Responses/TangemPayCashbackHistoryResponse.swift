//
//  TangemPayCashbackHistoryResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCashbackHistoryResponse: Decodable {
    @DefaultIfMissing
    public var items: [Item]
}

// MARK: - Nested Types

public extension TangemPayCashbackHistoryResponse {
    struct Item: Codable {
        public let year: Int

        /// Range of 1-12
        public let month: Int

        public let confirmedAmount: String
    }
}
