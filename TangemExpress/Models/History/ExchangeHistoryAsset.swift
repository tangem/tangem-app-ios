//
//  ExchangeHistoryAsset.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeHistoryAsset: Hashable {
    public let network: String
    public let tokenId: String?
    public let amount: Decimal
    public let decimals: Int
    /// Only meaningful on the `to` side of a swap. `true` — finalised amount,
    /// `false`/`nil` — estimate that may still change.
    public let isActual: Bool?

    public init(network: String, tokenId: String?, amount: Decimal, decimals: Int, isActual: Bool?) {
        self.network = network
        self.tokenId = tokenId
        self.amount = amount
        self.decimals = decimals
        self.isActual = isActual
    }
}
