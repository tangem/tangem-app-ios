//
//  OnrampHistoryAsset.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryAsset: Hashable {
    public let network: String
    public let tokenId: String?
    /// Estimated payout amount fixed at order time.
    public let expectedAmount: Decimal
    /// Final delivered amount. `nil` until the order finalises.
    public let actualAmount: Decimal?
    public let decimals: Int
}
