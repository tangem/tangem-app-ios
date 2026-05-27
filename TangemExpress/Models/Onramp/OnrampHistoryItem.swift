//
//  OnrampHistoryItem.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryItem: Codable, Equatable {
    public let txId: String
    public let status: OnrampTransactionStatus
    public let createdAt: Date

    public let fromCurrencyCode: String
    public let fromAmount: Decimal

    public let toContractAddress: String
    public let toNetwork: String
    public let toAmount: Decimal?
    public let toActualAmount: Decimal?

    public let externalTxId: String?
    public let externalTxUrl: String?
}
