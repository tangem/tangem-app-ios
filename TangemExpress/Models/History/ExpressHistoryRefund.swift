//
//  ExpressHistoryRefund.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressHistoryRefund: Hashable {
    public let network: String
    public let tokenId: String?
    public let amount: Decimal
    public let decimals: Int
    public let hash: String?

    public init(network: String, tokenId: String?, amount: Decimal, decimals: Int, hash: String?) {
        self.network = network
        self.tokenId = tokenId
        self.amount = amount
        self.decimals = decimals
        self.hash = hash
    }
}
